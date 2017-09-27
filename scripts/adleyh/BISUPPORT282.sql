SELECT 
	a.course_id, 
	b.cnt_total_enrolls,
	SUM(cnt_registrations) AS cnt_new_enrollments
FROM 
	cnt_registrations_course a 
JOIN
(
    SELECT
	    course_id,
	    COUNT(1) AS cnt_total_enrolls
    FROM 
    	production.d_user_course
    WHERE 
    	first_enrollment_time >= '2017-03-13'
	GROUP BY 
		course_id
) b
ON 
	a.course_id = b.course_id
AND
	a.date >= '2017-03-13'
GROUP BY 
	1,2;

DROP TABLE IF EXISTS ahemphill.first_course_subsequent_engagement;
CREATE TABLE IF NOT EXISTS ahemphill.first_course_subsequent_engagement AS

SELECT
	a.user_id,
	a.label AS first_enrolled_course,
	b.course_id,
	CASE WHEN b.course_id IS NOT NULL THEN 1 ELSE 0 END AS is_enrolled,
	CASE WHEN c.course_id IS NOT NULL THEN 1 ELSE 0 END AS is_engaged
FROM 
	experimental_events_run14.event_records a
JOIN
	production.d_user_course b
ON 
	a.user_id = b.user_id
AND 
	a.event_type = 'edx.bi.user.account.registered'
AND
	DATE(received_at) >= '2017-03-13'
AND
	a.label IS NOT NULL
AND
	CASE
		WHEN a.label IN (
	'course-v1:MichiganX+teachout.1x+1T2017',
	'course-v1:MichiganX+teachout.2x+1T2017',
	'course-v1:MichiganX+teachout.3x+2T2017',
	'course-v1:MichiganX+teachout.4x+2T2017'
	) THEN b.course_id NOT IN (
	'course-v1:MichiganX+teachout.1x+1T2017',
	'course-v1:MichiganX+teachout.2x+1T2017',
	'course-v1:MichiganX+teachout.3x+2T2017',
	'course-v1:MichiganX+teachout.4x+2T2017'
	) 
		ELSE a.label != b.course_id
	END
LEFT JOIN
(
	SELECT
		user_id,
		course_id
	FROM
		production.f_user_activity
	WHERE
		activity_type != 'ACTIVE'
	GROUP BY
		user_id,
		course_id
) c
ON
	b.user_id = c.user_id
AND
	b.course_id = c.course_id;

SELECT
	first_enrolled_course,
	cnt_reg_users,
	SUM(cnt_enrolls) AS cnt_enrolls,
	COUNT(DISTINCT user_id) AS cnt_enrolled_users,
	SUM(cnt_engaged_enrolls) AS cnt_engaged_enrolls,
	SUM(is_engaged) AS cnt_engaged_users
FROM
(
	SELECT 
		user_id,
		first_enrolled_course,
		COUNT(1) AS cnt_enrolls,
		SUM(is_engaged) AS cnt_engaged_enrolls,
		MAX(is_engaged) as is_engaged 
	FROM 
		ahemphill.first_course_subsequent_engagement
	GROUP BY
		user_id,
		first_enrolled_course
) a
JOIN
(
SELECT
	course_id,
	SUM(cnt_registrations) AS cnt_reg_users
FROM
	cnt_registrations_course
WHERE
	date >= '2017-03-13'
GROUP BY 
	course_id
) b
ON
	a.first_enrolled_course = b.course_id
GROUP BY
	1,2

