DROP TABLE IF EXISTS ahemphill.acct_activation_verify_attempt;
CREATE TABLE ahemphill.acct_activation_verify_attempt AS

SELECT 
	a.user_id,
	a.acct_type,
	regexp_replace(regexp_replace(a.course_id, '%3A',':'), '%2B','+') AS course_id
FROM
(
	SELECT 
		CAST(user_id AS VARCHAR) AS user_id,
		'new_acct' AS acct_type,
		regexp_substr(path, 'course.*?(?=\/)') AS course_id
	FROM 
		experimental_events_run14.event_records 
	WHERE
		path like '/verify_student/start-flow/%' 
		AND event_type = 'identify'
	GROUP BY
		user_id, 2, 3

	UNION ALL

	SELECT 
		CAST(user_id AS VARCHAR) AS user_id,
		'old_acct' AS acct_type,
		regexp_substr(referrer, 'course-.*?(?=\/)') AS course_id
	FROM 
		experimental_events_run14.event_records 
	WHERE
		path = '/basket/' 
		AND referrer like '%course_modes/choose/%'
		AND event_type = 'identify'
	GROUP BY
		user_id, 2, 3

) a;

DROP TABLE IF EXISTS ahemphill.acct_activation_verify_attempt_summary;
CREATE TABLE ahemphill.acct_activation_verify_attempt_summary AS

SELECT 
        b.acct_type,
        a.course_id,
        COUNT(1) AS cnt_verify_button_click,
        COUNT(DISTINCT a.user_id) AS cnt_verify_button_click,
        COUNT(first_verified_enrollment_time) AS cnt_verifs
FROM 
	production.d_user_course a
JOIN 
	ahemphill.acct_activation_verify_attempt b
ON a.user_id = b.user_id
AND a.course_id = b.course_id
GROUP BY
	b.acct_type,
	a.course_id;


----

SELECT 
        b.acct_type,
        a.course_id,
        COUNT(1) AS cnt_verify_button_click,
        COUNT(DISTINCT a.user_id) AS cnt_verify_button_click,
        COUNT(first_verified_enrollment_time) AS cnt_verifs
FROM 
	production.d_user_course a
JOIN ahemphill.acct_activation_verify_attempt b
ON a.user_id = b.user_id
AND a.course_id = b.course_id
JOIN 
	(
	  SELECT
	  user_id,
	  course_id,
	  COUNT(DISTINCT acct_type) as cnt_acct_type
	  FROM ahemphill.acct_activation_verify_attempt
	  GROUP BY 1,2
	  HAVING COUNT(DISTINCT acct_type) = 1
	  ) c
	  ON cast(a.user_id as varchar) = cast(c.user_id as varchar)
	  and a.course_id = c.course_id
GROUP BY
	b.acct_type,
	a.course_id;