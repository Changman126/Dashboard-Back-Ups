DROP TABLE IF EXISTS ahemphill.course_enrollment_verif_agg;
CREATE TABLE ahemphill.course_enrollment_verif_agg AS

SELECT
	a.course_id,
	c.catalog_course_title,
	b.program_type,
	b.program_title,
	c.start_time AS course_start_time,
	c.end_time AS course_end_time,
	c.enrollment_start_time AS course_enrollment_start_time,
	c.enrollment_end_time AS course_enrollment_end_time,
	c.pacing_type AS course_pacing_type,
	c.level_type AS course_level_type,
	c.availability AS course_availability,
	d.course_seat_price,
	d.course_seat_upgrade_deadline,
	COUNT(1) AS cnt_enrolls,
	CASE WHEN
	d.course_seat_upgrade_deadline IS NOT NULL 
	THEN SUM(CASE WHEN a.first_verified_enrollment_time <= d.course_seat_upgrade_deadline THEN 1 ELSE 0 END)
	ELSE SUM(CASE WHEN a.first_verified_enrollment_time IS NOT NULL THEN 1 ELSE 0 END) 
	END AS cnt_verifs,
	SUM(e.has_passed) AS cnt_passed
FROM
	d_user_course a
LEFT JOIN
	d_program_course b
ON a.course_id = b.course_id
LEFT JOIN
	d_course c
ON a.course_id = c.course_id
LEFT JOIN
	d_course_seat d
ON a.course_id = d.course_id
AND d.course_seat_type = 'verified'
LEFT JOIN
	d_user_course_certificate e
ON a.user_id = e.user_id
AND a.course_id = e.course_id
AND a.current_enrollment_mode = e.certificate_mode
 
GROUP BY
	a.course_id,
	c.catalog_course_title,
	b.program_type,
	b.program_title,
	c.start_time,
	c.end_time,
	c.enrollment_start_time,
	c.enrollment_end_time,
	c.pacing_type,
	c.level_type,
	c.availability,
	d.course_seat_price,
	d.course_seat_upgrade_deadline


select * from ahemphill.course_enrollment_verif_agg where program_type = 'MicroMasters' limit 1000
