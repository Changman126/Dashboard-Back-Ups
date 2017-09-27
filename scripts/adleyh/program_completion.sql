
DROP TABLE IF EXISTS ahemphill.course_completion_consolidated;
CREATE TABLE IF NOT EXISTS ahemphill.course_completion_consolidated AS
SELECT
	course.user_id,
	course.course_id,
	course.letter_grade,
	CASE
		WHEN course.passed_timestamp IS NOT NULL AND 
		course.passed_timestamp > sub.max_first_attempted THEN sub.max_first_attempted
		WHEN course.passed_timestamp IS NOT NULL AND 
		course.passed_timestamp <= sub.max_first_attempted THEN course.passed_timestamp
		ELSE NULL
	END AS passed_timestamp
FROM
	lms_read_replica.grades_persistentcoursegrade course
LEFT JOIN
	(
	SELECT 
		user_id,
		course_id,
		MAX(first_attempted) AS max_first_attempted
	FROM 
		lms_read_replica.grades_persistentsubsectiongrade
	GROUP BY 
		user_id,
		course_id
	) sub
ON
	course.user_id = sub.user_id
AND
	course.course_id = sub.course_id;

DROP TABLE IF EXISTS ahemphill.program_completion_stg;
CREATE TABLE IF NOT EXISTS ahemphill.program_completion_stg AS

SELECT
	a.user_id,
	b.course_number,
	c.program_type,
	c.program_title,
	MIN(a.first_enrollment_time) AS first_enrollment_time,
	MAX(CASE
		WHEN a.current_enrollment_mode NOT IN ('audit','honor') THEN 1
		ELSE 0
	END) AS is_verified,
	CASE WHEN MAX(passed_timestamp) IS NOT NULL THEN 1 ELSE 0 END AS has_passed,
	MAX(passed_timestamp) AS last_pass_time
FROM
	production.d_user_course a
JOIN
	course_master b
ON
	a.course_id = b.course_id
JOIN
(
	SELECT 
		DISTINCT program_type,
		program_title,
		catalog_course
	FROM 
		production.d_program_course
) c
ON
	b.course_number = c.catalog_course
LEFT JOIN
	ahemphill.course_completion_consolidated d
ON
	a.user_id = d.user_id
AND
	a.course_id = d.course_id
GROUP BY
	a.user_id,
	b.course_number,
	c.program_type,
	c.program_title;

DROP TABLE IF EXISTS ahemphill.program_completion;
CREATE TABLE IF NOT EXISTS ahemphill.program_completion AS

SELECT
	a.user_id,
	a.program_type,
	a.program_title,
	b.cnt_courses_in_program,
	SUM(is_verified) AS cnt_verified,
	COUNT(DISTINCT course_number) AS cnt_enrolled,
	SUM(has_passed) AS cnt_passed,
	SUM(has_passed)  * 100.0/b.cnt_courses_in_program AS pct_complete_of_program,
	CASE WHEN SUM(has_passed) = b.cnt_courses_in_program THEN 1 ELSE 0 END AS program_completion
FROM
	ahemphill.program_completion_stg a
JOIN
(
	SELECT 
		program_type,
		program_title,
		COUNT(DISTINCT catalog_course) AS cnt_courses_in_program
	FROM 
		production.d_program_course
	GROUP BY 
		program_type,
		program_title
) b

ON
	a.program_type = b.program_type
AND
	a.program_title = b.program_title

GROUP BY
	a.user_id,
	a.program_type,
	a.program_title,
	b.cnt_courses_in_program
HAVING
	SUM(is_verified) > 1;

DROP TABLE IF EXISTS ahemphill.program_completion_summary;
CREATE TABLE IF NOT EXISTS ahemphill.program_completion_summary AS

SELECT
	cal.date,
	completions.*,
	CASE WHEN program_complete_time <= cal.date THEN 1 ELSE 0 END AS eligible_program_completion
FROM
(
SELECT
	completion.*,
	program_times.program_start_time,
	CASE 
		WHEN completion.program_completion = 1 
		THEN program_times.program_complete_time 
		ELSE NULL 
	END AS program_complete_time
FROM
	ahemphill.program_completion completion
JOIN
(
	SELECT
		user_id,
		program_type,
		program_title,
		MIN(first_enrollment_time) AS program_start_time,
		MAX(last_pass_time) AS program_complete_time
	FROM
		ahemphill.program_completion_stg
	GROUP BY
		user_id,
		program_type,
		program_title
) program_times
ON
	completion.user_id = program_times.user_id
AND
	completion.program_type = program_times.program_type
AND
	completion.program_title = program_times.program_title
) completions
JOIN
	calendar cal
ON
	cal.date BETWEEN DATE(program_start_time) AND '2018-07-01'
	-- CASE 
	-- 	WHEN CURRENT_DATE() < DATE(program_start_time) + 365*2 THEN CURRENT_DATE 
	-- 	ELSE DATE(program_start_time) + 365*2 
	-- END;

DROP TABLE IF EXISTS ahemphill.program_completion_summary_stg;
CREATE TABLE IF NOT EXISTS ahemphill.program_completion_summary_stg AS

SELECT
	a.date,
	a.user_id,
	a.program_type,
	a.program_title,
	a.cnt_courses_in_program,
	a.eligible_program_completion,
	a.program_start_time,
	b.last_pass_time,
	SUM(CASE 
		WHEN last_pass_time IS NOT NULL THEN 1 
		ELSE 0 END) OVER (PARTITION BY a.user_id, a.program_type, a.program_title ORDER BY date asc) AS cumulative_courses_passed,
	SUM(CASE 
		WHEN last_pass_time IS NOT NULL THEN 1 
		ELSE 0 END) OVER (PARTITION BY a.user_id, a.program_type, a.program_title ORDER BY date asc)*100.0/cnt_courses_in_program AS pct_progress
FROM
	ahemphill.program_completion_summary a
LEFT JOIN
	ahemphill.program_completion_stg b
ON
	a.user_id = b.user_id
AND
	a.program_type = b.program_type
AND
	a.program_title = b.program_title
AND
	a.date = DATE(b.last_pass_time);

DROP TABLE IF EXISTS ahemphill.program_completion_summary_window;
CREATE TABLE IF NOT EXISTS ahemphill.program_completion_summary_window AS

SELECT * FROM
(
SELECT
	*,
	'6_months' AS window
FROM
	ahemphill.program_completion_summary_stg
WHERE
	DATE(program_start_time) = DATE(date) - (6*30)

UNION ALL

SELECT
	*,
	'12_months' AS window
FROM
	ahemphill.program_completion_summary_stg
WHERE
	DATE(program_start_time) = DATE(date) - (12*30)

UNION ALL

SELECT
	*,
	'18_months' AS window
FROM
	ahemphill.program_completion_summary_stg
WHERE
	DATE(program_start_time) = DATE(date) - (18*30)

UNION ALL

SELECT
	*,
	'24_months' AS window
FROM
	ahemphill.program_completion_summary_stg
WHERE
	DATE(program_start_time) = DATE(date) - (24*30)
) a;


/*


Now trying this, but with a less strict criteria for being included in the calc

*/



DROP TABLE IF EXISTS ahemphill.program_completion_stg_less_strict;
CREATE TABLE IF NOT EXISTS ahemphill.program_completion_stg_less_strict AS

SELECT
	a.user_id,
	b.course_number,
	c.program_type,
	c.program_title,
	MIN(a.first_enrollment_time) AS first_enrollment_time,
	MAX(CASE
		WHEN a.current_enrollment_mode NOT IN ('audit','honor') THEN 1
		ELSE 0
	END) AS is_verified,
	CASE WHEN MAX(passed_timestamp) IS NOT NULL THEN 1 ELSE 0 END AS has_passed,
	MAX(passed_timestamp) AS last_pass_time
FROM
	production.d_user_course a
JOIN
	course_master b
ON
	a.course_id = b.course_id
JOIN
(
	SELECT 
		DISTINCT program_type,
		program_title,
		catalog_course
	FROM 
		production.d_program_course
) c
ON
	b.course_number = c.catalog_course
LEFT JOIN
	ahemphill.course_completion_consolidated d
ON
	a.user_id = d.user_id
AND
	a.course_id = d.course_id
GROUP BY
	a.user_id,
	b.course_number,
	c.program_type,
	c.program_title;

DROP TABLE IF EXISTS ahemphill.program_completion_less_strict;
CREATE TABLE IF NOT EXISTS ahemphill.program_completion_less_strict AS

SELECT
	a.user_id,
	a.program_type,
	a.program_title,
	b.cnt_courses_in_program,
	SUM(is_verified) AS cnt_verified,
	COUNT(DISTINCT course_number) AS cnt_enrolled,
	SUM(has_passed) AS cnt_passed,
	SUM(has_passed)  * 100.0/b.cnt_courses_in_program AS pct_complete_of_program,
	CASE WHEN SUM(has_passed) = b.cnt_courses_in_program THEN 1 ELSE 0 END AS program_completion
FROM
	ahemphill.program_completion_stg_less_strict a
JOIN
(
	SELECT 
		program_type,
		program_title,
		COUNT(DISTINCT catalog_course) AS cnt_courses_in_program
	FROM 
		production.d_program_course
	GROUP BY 
		program_type,
		program_title
) b

ON
	a.program_type = b.program_type
AND
	a.program_title = b.program_title

GROUP BY
	a.user_id,
	a.program_type,
	a.program_title,
	b.cnt_courses_in_program
HAVING
	SUM(is_verified) > 0;

DROP TABLE IF EXISTS ahemphill.program_completion_summary_less_strict;
CREATE TABLE IF NOT EXISTS ahemphill.program_completion_summary_less_strict AS

SELECT
	cal.date,
	completions.*,
	CASE WHEN program_complete_time <= cal.date THEN 1 ELSE 0 END AS eligible_program_completion
FROM
(
	SELECT
		completion.*,
		program_times.program_start_time,
		CASE 
			WHEN completion.program_completion = 1 
			THEN program_times.program_complete_time 
			ELSE NULL 
		END AS program_complete_time
	FROM
		ahemphill.program_completion_less_strict completion
	JOIN
	(
		SELECT
			user_id,
			program_type,
			program_title,
			MIN(first_enrollment_time) AS program_start_time,
			MAX(last_pass_time) AS program_complete_time
		FROM
			ahemphill.program_completion_stg_less_strict
		GROUP BY
			user_id,
			program_type,
			program_title
	) program_times
	ON
		completion.user_id = program_times.user_id
	AND
		completion.program_type = program_times.program_type
	AND
		completion.program_title = program_times.program_title
) completions
JOIN
	calendar cal
ON
	cal.date BETWEEN DATE(program_start_time) AND '2018-07-01'
	-- CASE 
	-- 	WHEN CURRENT_DATE() < DATE(program_start_time) + 365*2 THEN CURRENT_DATE 
	-- 	ELSE DATE(program_start_time) + 365*2 
	-- END;

DROP TABLE IF EXISTS ahemphill.program_completion_summary_stg_less_strict;
CREATE TABLE IF NOT EXISTS ahemphill.program_completion_summary_stg_less_strict AS

SELECT
	a.date,
	a.user_id,
	a.program_type,
	a.program_title,
	a.cnt_courses_in_program,
	a.eligible_program_completion,
	a.program_start_time,
	b.last_pass_time,
	SUM(CASE 
		WHEN last_pass_time IS NOT NULL THEN 1 
		ELSE 0 END) OVER (PARTITION BY a.user_id, a.program_type, a.program_title ORDER BY date asc) AS cumulative_courses_passed,
	SUM(CASE 
		WHEN last_pass_time IS NOT NULL THEN 1 
		ELSE 0 END) OVER (PARTITION BY a.user_id, a.program_type, a.program_title ORDER BY date asc)*100.0/cnt_courses_in_program AS pct_progress
FROM
	ahemphill.program_completion_summary_less_strict a
LEFT JOIN
	ahemphill.program_completion_stg_less_strict b
ON
	a.user_id = b.user_id
AND
	a.program_type = b.program_type
AND
	a.program_title = b.program_title
AND
	a.date = DATE(b.last_pass_time);

DROP TABLE IF EXISTS ahemphill.program_completion_summary_window_less_strict;
CREATE TABLE IF NOT EXISTS ahemphill.program_completion_summary_window_less_strict AS

SELECT * FROM
(
SELECT
	*,
	'6_months' AS window
FROM
	ahemphill.program_completion_summary_stg_less_strict
WHERE
	DATE(program_start_time) = DATE(date) - (6*30)

UNION ALL

SELECT
	*,
	'12_months' AS window
FROM
	ahemphill.program_completion_summary_stg_less_strict
WHERE
	DATE(program_start_time) = DATE(date) - (12*30)

UNION ALL

SELECT
	*,
	'18_months' AS window
FROM
	ahemphill.program_completion_summary_stg_less_strict
WHERE
	DATE(program_start_time) = DATE(date) - (18*30)

UNION ALL

SELECT
	*,
	'24_months' AS window
FROM
	ahemphill.program_completion_summary_stg_less_strict
WHERE
	DATE(program_start_time) = DATE(date) - (24*30)
) a;
