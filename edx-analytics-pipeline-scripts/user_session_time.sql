CREATE TABLE IF NOT EXISTS business_intelligence.user_session_summary (
	date DATE,
	anonymous_id VARCHAR(255),
	user_id VARCHAR(255),
	event_type VARCHAR(255),
	event_category VARCHAR(255),
	agent_type VARCHAR(255),
	agent_device_name VARCHAR(255),
	agent_browser VARCHAR(255),
	domain VARCHAR(2047),
	session_number INTEGER,
	course_id VARCHAR(255),
	session_length_sec INTEGER,
	cnt_page_views INTEGER
);

--dummy insert to initialize the table

INSERT INTO business_intelligence.user_session_summary (date)
SELECT
    '2012-08-31' 
FROM 
    business_intelligence.user_session_summary
HAVING 
    COUNT(date)=0;

--track all page views for all anonymous_id along with timestamp of pageview and timestamp of previous pageview

DROP TABLE IF EXISTS tmp_user_session_stg;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_user_session_stg ON COMMIT PRESERVE ROWS AS

SELECT
	anonymous_id,
	CAST(received_at AS TIMESTAMPTZ) AS received_at_timestamp,
	agent_type,
	agent_device_name,
	agent_browser,
	SPLIT_PART(url, '/', 3) AS domain,
	event_type,
	event_category,
	path,
	CASE 
        WHEN STRPOS(path, '%') = 0 THEN REGEXP_SUBSTR(path, '/courses/([^/+]+(/|\+)[^/+]+(/|\+)[^/?]+)/', 1, 1, '', 1)
        ELSE URI_PERCENT_DECODE(REGEXP_SUBSTR(path, '/courses/([^/+]+(/|\+)[^/+]+(/|\+)[^/?]+)/', 1, 1, '', 1))
    END AS course_id,
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
ON
    DATE(received_at) > summary.latest_date
AND
	event_type = 'page'
AND
	anonymous_id IS NOT NULL
AND 
	project = 'hqawk62tyf';

--apply the GA definition of a session: https://support.google.com/analytics/answer/2731565?hl=en
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
	agent_type,
	agent_device_name,
	agent_browser,
	domain,
    course_id,
    path,
	last_action_timestamp,
	CASE 
		WHEN (received_at_timestamp - last_action_timestamp) > '30 minutes'
  		OR DATE(last_action_timestamp) != DATE(received_at_timestamp) THEN 0 
  		ELSE COALESCE(TIMESTAMPDIFF('second',  last_action_timestamp, received_at_timestamp), 0) 
  	END AS diff_sec,
	CONDITIONAL_TRUE_EVENT(
	  (received_at_timestamp - last_action_timestamp) > '30 minutes'
	  OR DATE(last_action_timestamp) != DATE(received_at_timestamp)
	) OVER(PARTITION BY anonymous_id ORDER BY received_at_timestamp) AS session_number
FROM 
	tmp_user_session_stg;


--aggregate daily information, combine it with previous days data, and join to identify to try to map anonymous_id to user_id

DROP TABLE IF EXISTS tmp_user_session_summary;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_user_session_summary ON COMMIT PRESERVE ROWS AS

SELECT 
	session.date,
	session.anonymous_id,
	id.user_id,
	session.event_type,
	session.event_category,
	session.agent_type,
	session.agent_device_name,
	session.agent_browser,
	session.domain,
	session.session_number,
	session.course_id,
	session.session_length_sec,
	session.cnt_page_views
FROM 
	(
		SELECT 
			DATE(received_at_timestamp) AS date,
			anonymous_id,
			event_type,
			event_category,
			agent_type,
			agent_device_name,
			agent_browser,
			domain,
			session_number + 1 AS session_number,
			course_id,
			SUM(diff_sec) AS session_length_sec,
			COUNT(1) AS cnt_page_views
		FROM 
			tmp_user_session
		GROUP BY
			DATE(received_at_timestamp),
			anonymous_id,
			event_type,
			event_category,
			agent_type,
			agent_device_name,
			agent_browser,
			domain,
			(session_number + 1),
			course_id

		UNION DISTINCT

		SELECT
			date,
			anonymous_id,
			event_type,
			event_category,
			agent_type,
			agent_device_name,
			agent_browser,
			domain,
			session_number,
			course_id,
			session_length_sec,
			cnt_page_views
		FROM
			business_intelligence.user_session_summary
	) session
LEFT JOIN
	business_intelligence.identify id
ON
	session.anonymous_id = id.anonymous_id;

DROP TABLE IF EXISTS business_intelligence.user_session_summary;
CREATE TABLE business_intelligence.user_session_summary AS 
SELECT
	*
FROM
	tmp_user_session_summary;

DROP TABLE IF EXISTS tmp_user_session_stg;
DROP TABLE IF EXISTS tmp_user_session_summary;