DROP TABLE IF EXISTS course_availability;
CREATE TABLE IF NOT EXISTS course_availability AS

SELECT 
	cal.date,
	course.course_subject,
	course.course_start_date,
	course.course_end_date,
	course.course_announcement_date,
	course.course_verification_end_date,
	course.course_seat_price,
	course.content_language AS course_content_language,
	course.pacing_type AS course_pacing_type,
	course.level_type AS course_level_type,
	course.course_run_number,
	course.course_partner,
	course.course_reporting_type,
	CASE 
		WHEN cal.date BETWEEN course.course_announcement_date AND course.course_end_date THEN 1 
		ELSE 0 
	END AS is_course_enrollable,
	CASE 
		WHEN cal.date BETWEEN course.course_start_date AND course.course_end_date THEN 1 
		ELSE 0 
	END AS is_course_running,
	CASE 
		WHEN cal.date BETWEEN course.course_announcement_date AND course.course_verification_end_date THEN 1 
		ELSE 0 
	END AS is_course_verifiable
FROM
	course_master course
FULL OUTER JOIN
	calendar cal
ON 
	1=1;