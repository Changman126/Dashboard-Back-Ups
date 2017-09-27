SELECT
	CASE WHEN cnt_courses_enrolled > 0 then 'enrolled other data courses' else 'not enrolled other data courses' end,
	COUNT(1) AS cnt_users
FROM
(
	SELECT
		a.user_id,
		SUM(case when c.course_subject is not null 
		and d.program_id != '482dee71-e4b9-4b42-a47b-3e16bb69e8f2' THEN 1 ELSE 0 END) AS cnt_courses_enrolled
	FROM
	(
		SELECT
			user_id,
			MIN(first_enrollment_time) AS first_enrollment_time
		FROM 
			production.d_program_course a
		JOIN 
			production.d_user_course b
		ON 
			a.program_id = '482dee71-e4b9-4b42-a47b-3e16bb69e8f2'
		AND 
			a.course_id = b.course_id
		GROUP by
			1
	) a
	LEFT JOIN
		production.d_user_course b
	ON
		a.user_id = b.user_id
	AND
		a.first_enrollment_time < b.first_enrollment_time
	LEFT JOIN
		course_master c
	ON
		b.course_id = c.course_id
	AND
		c.course_subject LIKE '%Data%'
	LEFT JOIN
		production.d_program_course d
	ON
		b.course_id = d.course_id
	GROUP BY 
		1
) a
GROUP BY 
	1