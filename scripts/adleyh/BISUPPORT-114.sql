select
	has_non_archived_enrollment,
	COUNT(1) AS cnt_users
FROM
(
	SELECT
		user_id,
		MAX(is_non_archived_course) AS has_non_archived_enrollment
	FROM
	(
		SELECT
			a.user_id,
			first_course_id,
			course_status_at_time_of_enroll,
			CASE
			        WHEN b.first_enrollment_time <= c.end_time THEN 1
			        WHEN b.first_enrollment_Time IS NULL THEN 0
			         
			        ELSE 0
			END AS is_non_archived_course,
			b.course_id,
			b.first_enrollment_time
		FROM
		(
			SELECT
				user_id,
				first_course_id,
				first_course_enrollment_date,
				b.start_time,
				b.end_time,
				CASE
				        WHEN first_course_enrollment_date <= b.end_time THEN 'Non-Archived'
				        ELSE 'Archived'
				END AS course_status_at_time_of_enroll
			from 
				ahemphill.tmp_user_first_course a
			join 
				d_course b
			on a.first_course_id = b.course_id
			AND b.start_time IS NOT NULL
			AND b.end_time IS NOT NULL
			WHERE
			CASE
			        WHEN first_course_enrollment_date <= b.end_time THEN 'Non-Archived'
			        ELSE 'Archived'
			END = 'Archived'
		) a
		LEFT OUTER JOIN 
			d_user_course b
		on a.user_id = b.user_id
		AND a.first_course_id != b.course_id
		left OUTER JOIN
			d_course c
		ON b.course_id = c.course_id
		where c.end_time is not null
		AND c.start_time is not null
	) a
		group by 1
) a
group by 
	1