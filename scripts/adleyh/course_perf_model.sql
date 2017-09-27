select
	a.course_id,
	sum_enrolls,
	sum_enrolls/DATEDIFF('day', COALESCE(course_announcement_date, course_start_date), course_end_date) AS enrolls_days_open_norm,
	sum_enrolls/DATEDIFF('day', course_start_date, course_end_date) AS enrolls_course_length_norm,
	course_announcement_date,
	course_start_date,
	level_type,
	course_run_number,
	course_partner,
	pacing_type,
	COALESCE(course_subject, 'No Subject') AS course_subject,
	course_partner || '_' || COALESCE(course_subject, 'No Subject') AS course_subject_partner,
	course_partner || '_' || level_type AS course_level_partner,
	level_type || '_' || COALESCE(course_subject, 'No Subject') AS course_subject_level,
	COALESCE(course_seat_price,0) AS course_seat_price,
	content_language,
	DATEDIFF('day', course_announcement_date, course_end_date) AS course_length,
	COALESCE(c.program_type, 'Non-Program') AS program_type
from 
	business_intelligence.course_stats_summary a
join 
	business_intelligence.course_master b
on 
	a.course_id = b.course_id
and 
	course_start_date between '2016-04-26' and CURRENT_DATE()
AND 
	course_end_date between '2016-04-26' and CURRENT_DATE()
AND 
	pacing_type = 'instructor_paced'
AND 
	is_wl = 0
and 
	course_reporting_type = 'mooc'
left join 
	production.d_program_course c
on 
	a.course_id = c.course_id