SELECT
	user.*,
	course.course_org_id,
	course.course_start,
	course.course_end,
	course.course_name
FROM
	d_user_course user
JOIN
	d_course course
ON
	user.course_id = course.course_id
WHERE
	user.first_enrollment_time IS NOT NULL
LIMIT 10



---

SELECT
	course_run,
	count(1)
	--DISTINCT(course_run)
FROM
	d_course
WHERE
	course_name IS NOT NULL
group by 1

---

SELECT
	u.*,
	c.course_org_id,
	c.course_start,
	c.course_end,
	c.course_name,
	c.course_run,
	p.program_type,
	p.program_title,
	p.catalog_course,
	p.catalog_course_title,
	p.org_id,
	p.partner_short_code,
	TIMESTAMPDIFF('day', c.course_start, u.first_enrollment_time) AS enrollment_days_from_course_start,
	TIMESTAMPDIFF('day', c.course_start, u.first_verified_enrollment_time) AS verification_days_from_course_start,
	TIMESTAMPDIFF('day', u.first_enrollment_time, u.first_verified_enrollment_time) AS verification_days_from_enrollment
FROM
	production.d_user_course u
JOIN
	production.d_course c
ON
	u.course_id = c.course_id
LEFT JOIN 
	production.d_program_course p
ON 
	c.course_id = p.course_id
WHERE
	u.first_enrollment_time IS NOT NULL
	AND c.course_start IS NOT NULL
