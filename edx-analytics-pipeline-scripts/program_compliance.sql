--find the start date for compliance
--mapped to the earliest start date for the first course in a program

DROP TABLE IF EXISTS tmp_program_start_date;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_program_start_date ON COMMIT PRESERVE ROWS AS

SELECT 
	a.program_type,
	a.program_title,
	a.program_id,
	MIN(b.course_start_date) AS program_start_date
FROM 
	production.d_program_course a 
JOIN 
	business_intelligence.course_master b
ON 
	a.course_id = b.course_id
AND 
	a.program_slot_number = 1
AND
        b.course_start_date >= '2017-01-01'
GROUP BY
	a.program_type,
	a.program_title,
	a.program_id;


--determine whether program courses are in compliance. compliance defined as:
--instructor paced: 3 or more runs of course within 1 year of course start date
--self paced: 1 persistent across 1 year of course start date

DROP TABLE IF EXISTS business_intelligence.program_compliance;
CREATE TABLE IF NOT EXISTS business_intelligence.program_compliance AS

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
		tmp_program_start_date b
	ON
		a.program_id = b.program_id
	LEFT JOIN
		business_intelligence.course_master c
	ON
		a.course_id = c.course_id
	AND
		c.course_start_date BETWEEN b.program_start_date AND b.program_start_date + 365
	AND
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
	LEFT JOIN
		tmp_program_start_date b
	ON
		a.program_id = b.program_id
	LEFT JOIN
		business_intelligence.course_master c
	ON
		a.course_id = c.course_id
	AND
		c.course_start_date BETWEEN b.program_start_date AND (b.program_start_date + 365)
	AND 
		DATEDIFF('day', c.course_start_date, c.course_end_date) >= 365
	AND
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
