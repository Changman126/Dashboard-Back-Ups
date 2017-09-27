--track all page views for all anonymous_id along with timestamp of pageview and timestamp of previous pageview

DROP TABLE IF EXISTS tmp_user_session_stg;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_user_session_stg ON COMMIT PRESERVE ROWS AS

SELECT
	DATE(received_at),
	anonymous_id,
	CAST(received_at AS TIMESTAMPTZ) AS received_at_timestamp,
	event_type,
	event_category,
	path,
	label,
	CAST(LAG(received_at, 1) OVER (PARTITION BY anonymous_id ORDER BY received_at ASC) AS TIMESTAMPTZ) AS last_action_timestamp
FROM 
	experimental_events_run14.event_records event
JOIN
	(
		SELECT
			MAX(date) AS latest_date
		FROM
			business_intelligence.user_session_summary
	) summary
WHERE
    DATE(received_at) > summary.latest_date
AND
	event_type = 'page'
AND
	anonymous_id IS NOT NULL;

--apply the GA definitio of a session: https://support.google.com/analytics/answer/2731565?hl=en
--1) activity within the last 30m of the previous piece of activity
--2) resets on a new day

--bucket when a new session happens, then do a cumulative sum to track what number session it is for the anonymous_id
--on that day

DROP TABLE IF EXISTS tmp_user_session;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_user_session ON COMMIT PRESERVE ROWS AS

SELECT
	anonymous_id,
	received_at_timestamp,
	event_type,
	event_category,
	CASE
		WHEN path LIKE '%/courseware/%' THEN REPLACE(
	REPLACE(
		REPLACE(
			REGEXP_SUBSTR(path, '(course-v1.*?)/', 1, 1),'/',''),'%3',':'),'%2','+')
		ELSE 'non_courseware' 
	END AS course_id,
	last_action_timestamp,
	diff_sec,
	SUM(session_increment) OVER (PARTITION BY DATE(received_at_timestamp), anonymous_id ORDER BY received_at_timestamp) AS session_count
FROM
(
	SELECT
		anonymous_id,
		received_at_timestamp,
		event_type,
		event_category,
		path,
		last_action_timestamp,
		CASE 
			WHEN DATE(last_action_timestamp) != DATE(received_at_timestamp) THEN 0
			WHEN COALESCE(TIMESTAMPDIFF('minute' , last_action_timestamp, received_at_timestamp), 0) >= 30 THEN 0
			ELSE COALESCE(TIMESTAMPDIFF('second',  last_action_timestamp, received_at_timestamp), 0)
		END AS diff_sec,
		CASE 
			WHEN DATE(last_action_timestamp) != DATE(received_at_timestamp) THEN 0
			WHEN COALESCE(TIMESTAMPDIFF('minute' , last_action_timestamp, received_at_timestamp), 0) >= 30 THEN 1
			ELSE 0 
		END AS session_increment
	FROM
		tmp_user_session_stg
) a;

--aggregate daily information, combine it with previous days data, and join to identify to try to map anonymous_id to user_id

INSERT INTO business_intelligence.user_session_summary (

SELECT 
	session.date,
	session.anonymous_id,
	session.user_id,
	session_count,
	course_id,
	session_length_sec,
	unique_pages_viewed
FROM 
	(
		SELECT 
			DATE(received_at_timestamp) AS date,
			a.anonymous_id,
			b.user_id,
			session_count + 1 AS session_count,
			course_id,
			SUM(diff_sec) AS session_length_sec,
			COUNT(1) AS unique_pages_viewed
		FROM
			tmp_user_session
		GROUP BY
			1,2,3,4,5

		UNION ALL

		SELECT
			date,
			anonymous_id,
			user_id,
			session_count,
			course_id,
			session_length_sec,
			unique_pages_viewed
		FROM
			business_intelligence.user_session_summary
	) session
LEFT JOIN
	business_intelligence.identify id
ON
	session.anonymous_id = id.anonymous_id
);

