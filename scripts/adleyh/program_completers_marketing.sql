--find users who have completed a program (best approximation)

DROP TABLE IF EXISTS ahemphill.program_completers;
CREATE TABLE IF NOT EXISTS ahemphill.program_completers AS

SELECT 
	course.user_id, 
	b.program_type,
	b.program_title,
	b.program_id,
	courses_in_program,
	COUNT(course.course_id) AS cnt_enrolls,
		COUNT(DISTINCT course.course_id),
	SUM(is_certified) AS cnt_certs
FROM 
	production.d_user_course course
JOIN 
	production.d_program_course b
ON 
	course.course_id = b.course_id
JOIN
(
	SELECT
		program_title,
		program_id,
		MAX(program_slot_number) AS courses_in_program
	FROM 
		production.d_program_course

	GROUP BY
		program_title,
		program_id
) c
ON 
	b.program_id = c.program_id
LEFT JOIN
	production.d_user_course_certificate a
ON
	course.user_id = a.user_id
AND
	course.course_id = a.course_id
GROUP BY 
	1,2,3,4,5;

--find how many verified more than once in a single course
SELECT
	program_title,
	COUNT(DISTINCT user_id) AS cnt_users
FROM
(
SELECT
	a.user_id,
	a.program_title,
	b.catalog_course,
	SUM(CASE WHEN c.current_enrollment_mode = 'verified' THEN 1 ELSE 0 END) AS cnt_verifications,
	SUM(CASE WHEN d.passed_timestamp IS NULL THEN 1 ELSE 0 END) AS cnt_fails
FROM
	ahemphill.program_completers a
JOIN
	production.d_program_course b
ON
	a.program_title = b.program_title
AND
	b.program_type = 'MicroMasters'
JOIN
	production.d_user_course c
ON
	a.user_id = c.user_id
AND
	b.course_id = c.course_id
AND
	c.current_enrollment_mode = 'verified'
LEFT JOIN
	business_intelligence.course_completion_user d
ON
	a.user_id = d.user_id
AND
	b.course_id = d.course_id
GROUP BY
	1,2,3
HAVING
	SUM(CASE WHEN c.current_enrollment_mode = 'verified' THEN 1 ELSE 0 END) > 1
) a
GROUP BY
	1;

--when they verified more than once, how many times did they verify
--when they verified more than once, did they fail before?

SELECT
	a.user_id,
	a.program_title,
	b.catalog_course,
	SUM(CASE WHEN c.current_enrollment_mode = 'verified' THEN 1 ELSE 0 END) AS cnt_verifications,
	SUM(CASE WHEN d.passed_timestamp IS NULL THEN 1 ELSE 0 END) AS cnt_fails
FROM
	ahemphill.program_completers a
JOIN
	production.d_program_course b
ON
	a.program_title = b.program_title
AND
	b.program_type = 'MicroMasters'
JOIN
	production.d_user_course c
ON
	a.user_id = c.user_id
AND
	b.course_id = c.course_id
AND
	c.current_enrollment_mode = 'verified'
LEFT JOIN
	business_intelligence.course_completion_user d
ON
	a.user_id = d.user_id
AND
	b.course_id = d.course_id
GROUP BY
	1,2,3
HAVING
	SUM(CASE WHEN c.current_enrollment_mode = 'verified' THEN 1 ELSE 0 END) > 1;