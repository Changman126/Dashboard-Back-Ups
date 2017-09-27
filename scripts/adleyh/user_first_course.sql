DROP TABLE IF EXISTS ahemphill.user_first_course;
CREATE TABLE ahemphill.user_first_course AS
SELECT distinct
	a.user_id,
	b.user_account_creation_time AS registration_date,
	a.first_course,
	a.first_enrollment_time AS first_course_enrollment_date,
	c.startdate AS first_course_start_date,
	d.subject_title,
	DATEDIFF('day', b.user_account_creation_time, a.first_enrollment_time ) AS days_from_registration_to_first_enroll,
	e.first_verified_enrollment_time AS first_course_verified_enrollment_date,
	DATEDIFF('day', a.first_enrollment_time, e.first_verified_enrollment_time ) AS days_from_enroll_to_verification
FROM
(
	SELECT 
		distinct user_id,
		first_value(course_id) over (course_enrollment) as first_course,
		MIN(first_enrollment_time) OVER (course_enrollment) AS first_enrollment_time,
		first_verified_enrollment_time
	FROM
		d_user_course
	WINDOW
	        course_enrollment AS (partition by user_id order by first_enrollment_time asc)
) a 
JOIN
	d_user b
ON
	a.user_id = b.user_id
JOIN
	ed_services.CourseCatalog_20161017 c
ON
	a.first_course = c.CourseID
LEFT JOIN
	(
		SELECT
			course_id,
			subject_title,
			row_number() OVER (partition by course_id order by random()) AS rank
		FROM
			d_course_subjects
	) d
ON
	a.first_course = d.course_id
JOIN
	d_user_course e
ON
	a.user_id = e.user_id
	AND a.first_course = e.course_id
WHERE
	d.rank = 1
