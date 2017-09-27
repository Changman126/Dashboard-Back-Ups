select
	CASE 
		WHEN a.current_enrollment_mode = 'verified' THEN 'verified'
		ELSE 'audit'
	END AS current_enrollment_mode,
	a.course_id,
	c.course_subject,
	c.course_partner,
	c.course_name,
	c.course_seat_price,
	c.content_language,
	c.level_type,
	c.is_wl,
	COUNT(1) AS cnt_enrolls,
	COUNT(passed_timestamp) AS cnt_passed,
	COUNT(passed_timestamp) * 100.0/COUNT(1) AS completion_rate
FROM 
	business_intelligence.user_content_availability_date a
LEFT JOIN 
	business_intelligence.course_completion_user b
ON 
	a.user_id = b.user_id
AND 
	a.course_id = b.course_id
JOIN 
	business_intelligence.course_master c
ON 
	a.course_id = c.course_id
AND 
	c.pacing_type = 'instructor_paced'
AND 
	a.enroll_group = 'enroll_before_course_start'
AND 
	a.current_enrollment_mode IN ('honor','audit','verified')
GROUP BY 
	1,2,3,4,5,6,7,8,9
