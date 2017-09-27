--find users who have completed a program (best approximation)

DROP TABLE IF EXISTS ahemphill.program_completers;
CREATE TABLE IF NOT EXISTS ahemphill.program_completers AS

SELECT 
	user_id, 
	b.program_title, 
	courses_in_program, 
	SUM(is_certified) AS cnt_certs
FROM 
	production.d_user_course_certificate a 
JOIN 
	production.d_program_course b
ON 
	a.course_id = b.course_id
AND 
	b.program_type = 'MicroMasters'
JOIN
(
	SELECT
		program_title,
		MAX(program_slot_number) AS courses_in_program
	FROM 
		production.d_program_course
	WHERE 
		program_type = 'MicroMasters'
	AND
		program_title LIKE '%Supply Chain%'
	GROUP BY
		program_title
) c
ON 
	b.program_title = c.program_title
GROUP BY 
	1,2,3
HAVING 
	SUM(is_certified) = courses_in_program;

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