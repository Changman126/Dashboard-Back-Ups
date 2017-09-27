SELECT
	course_number,
	course_name,
	course_partner,
	course_subject,
	course_seat_price,
	SUM(sum_verifications)*100.0/SUM(sum_enrolls) AS weighted_vtr,
	AVG(sum_enrolls) AS avg_enrolls_per_run,
	AVG(sum_verifications) AS avg_verifications_per_run,
	AVG(sum_bookings) AS avg_bookings_per_run,
	COUNT(1) AS cnt_runs
FROM 
	course_master a 
JOIN 
	course_stats_summary b
ON 
	a.course_id = b.course_id
LEFT JOIN 
	production.d_program_course c
ON 
	a.course_id = c.course_id
WHERE 
	course_number IN
	(
		SELECT 
			course_number
		FROM 
			course_master
		WHERE 
			course_start_date BETWEEN '2017-09-01' AND '2017-12-31'
		AND 
			course_run_number > 1
	)
--AND course_start_date BETWEEN '2016-07-01' AND '2017-08-31'
AND 
	course_end_date BETWEEN '2016-07-01' AND '2017-08-31'
AND 
	sum_enrolls > 1000
AND 
	c.program_type IS NULL
AND 
	is_wl = 0
AND 
	course_seat_price < 99
GROUP BY
	course_number,
	course_name,
	course_partner,
	course_subject,
	course_seat_price