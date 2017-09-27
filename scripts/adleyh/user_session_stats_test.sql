DROP TABLE IF EXISTS ahemphill.user_session_test;
CREATE TABLE IF NOT EXISTS ahemphill.user_session_test AS
SELECT
	DATE(received_at),
	anonymous_id,
	CAST(received_at AS TIMESTAMPTZ) AS received_at_timestamp,
	agent_type,
	agent_device_name,
	agent_browser,
	SPLIT_PART(url, '/', 3) AS domain,
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
			ahemphill.user_session_summary
	) summary
ON
    DATE(received_at) > summary.latest_date
AND
	event_type = 'page'
AND
	anonymous_id IS NOT NULL
AND 
	project = 'hqawk62tyf';

DROP TABLE IF EXISTS ahemphill.user_session_test2;
CREATE TABLE IF NOT EXISTS ahemphill.user_session_test2 AS

SELECT
	anonymous_id,
	received_at_timestamp,
	event_type,
	event_category,
	agent_type,
	agent_device_name,
	agent_browser,
	domain,
	CASE
		WHEN path LIKE '%/courseware/%' THEN 
		COALESCE(
			REPLACE(
					REPLACE(
						REPLACE(REGEXP_SUBSTR(path, '(course-v1.*?)/', 1, 1),'/',''),
						'%3',':'),
				'%2','+'),
			REGEXP_SUBSTR(REPLACE(path,'/courses/',''), '([^/+]+(/|\+)[^/+]+(/|\+)[^/?]+)',1, 1)
		)
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
		agent_type,
		agent_device_name,
		agent_browser,
		domain,
		path,
		last_action_timestamp,
		CASE 
			WHEN DATE(last_action_timestamp) != DATE(received_at_timestamp) THEN 0
			WHEN COALESCE(TIMESTAMPDIFF('minute' , last_action_timestamp, received_at_timestamp), 0) > 30 THEN 0
			ELSE COALESCE(TIMESTAMPDIFF('second',  last_action_timestamp, received_at_timestamp), 0)
		END AS diff_sec,
		CASE 
			WHEN DATE(last_action_timestamp) != DATE(received_at_timestamp) THEN 0
			WHEN COALESCE(TIMESTAMPDIFF('minute' , last_action_timestamp, received_at_timestamp), 0) > 30 THEN 1
			ELSE 0 
		END AS session_increment
	FROM
		ahemphill.user_session_test
) a;

DROP TABLE IF EXISTS ahemphill.user_session_summary;
CREATE TABLE IF NOT EXISTS ahemphill.user_session_summary AS
SELECT 
	DATE(received_at_timestamp) AS date,
	a.anonymous_id,
	b.user_id,
	event_type,
	event_category,
	agent_type,
	agent_device_name,
	agent_browser,
	a.domain,
	session_count + 1 AS session_count,
	course_id,
	SUM(diff_sec) AS session_length_sec,
	COUNT(1) AS unique_pages_viewed
FROM 
	ahemphill.user_session_test2 a
LEFT JOIN
	identify b
ON
	a.anonymous_id = b.anonymous_id
GROUP BY
	DATE(received_at_timestamp),
	a.anonymous_id,
	b.user_id,
	event_type,
	event_category,
	agent_type,
	agent_device_name,
	agent_browser,
	a.domain,
	(session_count + 1),
	course_id;

