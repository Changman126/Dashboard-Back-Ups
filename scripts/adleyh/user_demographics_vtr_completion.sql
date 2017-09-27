DROP TABLE ahemphill.user_demographic_vtr_completion_rate;
CREATE TABLE ahemphill.user_demographic_vtr_completion_rate as
SELECT
	a.user_id,
	2017 - user_year_of_birth AS age,
	a.user_level_of_education,
	a.user_gender,
	a.user_last_location_country_code,
	b.course_id,
	b.current_enrollment_mode,
	c.has_passed,
	CASE WHEN date(first_enrollment_time) > d.course_verification_end_date THEN 0 ELSE 1 END AS vtr_eligible,
	d.course_seat_price,
	d.content_language,
	d.pacing_type,
	d.level_type,
	d.course_run_number,
	d.course_partner
FROM 
	production.d_user a
JOIN 
	production.d_user_course b
ON 
	a.user_id = b.user_id
AND 
	DATE(user_account_creation_time) >= '2016-01-01'
join 
	course_master d
ON 
	b.course_id = d.course_id
LEFT JOIN 
	production.d_user_course_certificate c
ON 
	a.user_id = c.user_id
AND 
	b.course_id = c.course_id
