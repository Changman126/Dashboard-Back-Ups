DROP TABLE IF EXISTS ahemphill.user_demographics_program_summary;
CREATE TABLE ahemphill.user_demographics_program_summary AS
SELECT
	a.type,
	b.program_type,
	a.value,
	SUM(a.cnt_value) AS cnt
FROM
(
SELECT
	'age' AS type,
	a.course_id,
	CAST((2016 - a.user_year_of_birth) AS VARCHAR) AS value,
	COUNT(1) AS cnt_value
FROM
	ahemphill.d_user_course_demographics a
JOIN d_course b
	ON a.course_id = b.course_id
	AND b.end_time >= '2016-01-01'
GROUP BY
	1,2,3

UNION ALL

SELECT
	'education' AS type,
	a.course_id,
	a.user_level_of_education,
	COUNT(1) AS cnt_value
FROM
	ahemphill.d_user_course_demographics a
JOIN d_course b
	ON a.course_id = b.course_id
	AND b.end_time >= '2016-01-01'
GROUP BY
	1,2,3

UNION ALL 

SELECT
	'country' AS type,
	a.course_id,
	a.user_last_location_country_code,
	COUNT(1) AS cnt_value
FROM
	ahemphill.d_user_course_demographics a
JOIN d_course b
	ON a.course_id = b.course_id
	AND b.end_time >= '2016-01-01'
GROUP BY
	1,2,3
) a
LEFT JOIN
	d_program_course b
ON a.course_id = b.course_id
GROUP BY 1,2,3

DROP TABLE IF EXISTS ahemphill.d_user_course_demographics;
CREATE TABLE ahemphill.d_user_course_demographics AS

SELECT
	a.*,
	b.user_year_of_birth,
	b.user_gender,
	b.user_level_of_education,
	b.user_last_location_country_code
FROM
	d_user_course a
JOIN
	d_user b
ON
	a.user_id = b.user_id

