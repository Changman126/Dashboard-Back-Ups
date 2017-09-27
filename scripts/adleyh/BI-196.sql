DROP TABLE IF EXISTS ahemphill.program_start_date;
CREATE TABLE IF NOT EXISTS ahemphill.program_start_date AS

SELECT 
	program_type,
	program_title,
	program_id,
	MIN(course_start_date) AS program_start_date
FROM 
	production.d_program_course a 
JOIN 
	course_master b
ON 
	a.course_id = b.course_id
AND 
	program_slot_number = 1
GROUP BY
	program_type,
	program_title,
	program_id;


SELECT
	program_type,
	program_title,
	program_id,
	program_start_date,
	course_number,
	MAX(cnt_courses) AS cnt_courses,
	MAX(is_compliant) AS is_compliant
FROM
(
	SELECT
		a.program_type,
		a.program_title,
		a.program_id,
		b.program_start_date,
		'instructor_paced' AS pacing_type,
		a.catalog_course AS course_number,
		COUNT(DISTINCT c.course_id) AS cnt_courses,
		CASE 
			WHEN COUNT(DISTINCT c.course_id) >= 3 THEN 1 
			ELSE 0
		END AS is_compliant
	FROM
		production.d_program_course a
	LEFT JOIN
		ahemphill.program_start_date b
	ON
		a.program_id = b.program_id
	JOIN
		business_intelligence.course_master c
	ON
		a.course_id = c.course_id
	AND
		c.course_start_date BETWEEN b.program_start_date AND b.program_start_date + 365
	WHERE
		c.pacing_type = 'instructor_paced'
	GROUP BY
		a.program_type,
		a.program_title,
		a.program_id,
		b.program_start_date,
		a.catalog_course,
		'instructor_paced' 

	UNION ALL

	SELECT
		a.program_type,
		a.program_title,
		a.program_id,
		b.program_start_date,
		'self_paced' AS pacing_type,
		a.catalog_course AS course_number,
		COUNT(DISTINCT c.course_id) AS cnt_courses,
		CASE 
			WHEN COUNT(DISTINCT c.course_id) >= 1 THEN 1 
			ELSE 0
		END AS is_compliant
	FROM
		production.d_program_course a
	JOIN
		ahemphill.program_start_date b
	ON
		a.program_id = b.program_id
	LEFT JOIN
		business_intelligence.course_master c
	ON
		a.course_id = c.course_id
	AND
		c.course_start_date <= b.program_start_date 
	AND 
		c.course_end_date >= (b.program_start_date + 365)
	WHERE
		c.pacing_type = 'self_paced'
	GROUP BY
		a.program_type,
		a.program_title,
		a.program_id,
		b.program_start_date,
		a.catalog_course,
		'self_paced'
) a
GROUP BY
	program_type,
	program_title,
	program_id,
	program_start_date,
	course_number;