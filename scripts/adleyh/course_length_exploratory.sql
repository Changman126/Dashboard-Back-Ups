DROP TABLE IF EXISTS ahemphill.course_length_exploratory;
CREATE TABLE IF NOT EXISTS ahemphill.course_length_exploratory AS

SELECT
	a.user_id,
	a.course_id,
	e.current_enrollment_mode,
	YEAR(c.course_start_date) AS course_year,
	d.vtr,
	CASE WHEN passed_timestamp IS NOT NULL THEN 1 ELSE 0 END AS has_completed,
	DATEDIFF('day', DATE(content_availability_date), DATE(passed_timestamp)) AS time_to_complete
FROM 
	business_intelligence.course_completion_user a 
JOIN 
	business_intelligence.user_content_availability_date b 
ON 
	a.user_id = b.user_id
AND 
	a.course_id = b.course_id
AND 
	enroll_group = 'enroll_before_course_start'
join 
	business_intelligence.course_master c
on 
	a.course_id = c.course_id
AND 
	c.pacing_type = 'instructor_paced'
AND
	YEAR(c.course_start_date) = 2017
JOIN 
	business_intelligence.course_stats_summary d
ON 
	a.course_id = d.course_id
JOIN
	production.d_user_course e
ON
	a.user_id = e.user_id
AND
	a.course_id = e.course_id
