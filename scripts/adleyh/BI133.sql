SELECT
	a.course_id,
	a.current_enrollment_mode,
	COUNT(1) AS cnt_enrolled,
	SUM(has_passed) AS cnt_passed
FROM
	production.d_user_course a
JOIN
	course_master b
ON
	a.course_id = b.course_id
AND
	b.pacing_type = 'instructor_paced'
AND
	b.course_start_date >= '2016-07-01'
LEFT JOIN
	production.d_user_course_certificate c
ON
	a.course_id = c.course_id
AND
	a.user_id = c.user_id
GROUP BY
	a.course_id,
	a.current_enrollment_mode


SELECT
	a.course_id,
	SUM(a.sum_bookings) as sum_bookings,
	MAX(b.is_wl) AS is_wl,
	b.course_partner
FROM 
	course_stats_time a 
JOIN 
	course_master b
ON 
	a.course_id = b.course_id
AND 
	a.sum_seat_bookings IS NOT NULL
AND 
	b.course_reporting_type = 'mooc'
AND 
	a.date >= '2016-04-21'
GROUP BY
	1,4

SELECT
	a.course_id,
	a.sum_bookings,
	b.is_wl,
	b.course_partner
FROM 
	course_stats_time a 
JOIN 
	course_master b
ON 
	a.course_id = b.course_id
AND 
	a.sum_seat_bookings IS NOT NULL
AND 
	b.course_reporting_type = 'mooc'