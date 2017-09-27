DROP TABLE IF EXISTS ahemphill.user_content_availability_date;
CREATE TABLE IF NOT EXISTS ahemphill.user_content_availability_date AS

SELECT
    user_course.user_id,
    user_course.course_id,
    CASE 
        WHEN DATE(user_course.first_enrollment_time) >= course.course_start_date THEN DATE(user_course.first_enrollment_time)
        ELSE course.course_start_date
    END AS content_availability_date,
    user_course.first_verified_enrollment_time,
    user_course.last_unenrollment_time
FROM 
    production.d_user_course user_course
JOIN 
    business_intelligence.course_master course
ON 
    user_course.course_id = course.course_id;

DROP TABLE IF EXISTS ahemphill.user_course_enrolls_time;
CREATE TABLE IF NOT EXISTS ahemphill.user_course_enrolls_time AS

SELECT
	b.date,
	a.user_id,
	a.course_id,
	a.content_availability_date,
	a.first_verified_enrollment_time,
	a.last_unenrollment_time,
	CASE 
		WHEN b.date BETWEEN a.content_availability_date AND COALESCE(a.last_unenrollment_time, '2017-12-31') THEN 1 
		ELSE 0 
	END AS is_enrolled,
	CASE 
		WHEN b.date BETWEEN a.content_availability_date AND COALESCE(a.first_verified_enrollment_time, '2017-12-31') THEN 0
		ELSE 1
	END AS is_verified
FROM 
	ahemphill.user_content_availability_date a
JOIN 
	calendar b
ON 
	DATE(a.content_availability_date) >= '2017-04-01'
AND 
	b.date BETWEEN a.content_availability_date AND CASE
	WHEN CURRENT_DATE() < (DATE(a.content_availability_date) + 90) THEN CURRENT_DATE()
	ELSE (DATE(a.content_availability_date) + 90)
END;

DROP TABLE IF EXISTS ahemphill.bulk_email_targets;
CREATE TABLE IF NOT EXISTS ahemphill.bulk_email_targets AS

SELECT
	send.id AS email_id, 
	send.sender_id,
	send.course_id,
	send.to_option,
	send.created AS created_timestamp,
	send.modified AS modified_timestamp,
	email_targets.target_type,
	cohort_targets.cohort_id, 
	track_targets.track_id,
	course_mode.mode_slug
FROM 
	lms_read_replica.bulk_email_courseemail send
JOIN 
	lms_read_replica.bulk_email_courseemail_targets courseemail_targets
ON 
	send.id = courseemail_targets.courseemail_id
AND
	send.to_option NOT IN ('staff', 'myself')
AND
	send.created >= '2016-07-01'
JOIN 
	lms_read_replica.bulk_email_target email_targets
ON 
	courseemail_targets.target_id = email_targets.id
AND
	email_targets.target_type NOT IN ('staff', 'myself')
LEFT JOIN 
	lms_read_replica.bulk_email_cohorttarget cohort_targets
ON 
	email_targets.id = cohort_targets.target_ptr_id
LEFT JOIN 
	lms_read_replica.bulk_email_coursemodetarget track_targets
ON 
	email_targets.id = track_targets.target_ptr_id
LEFT JOIN
	lms_read_replica.course_modes_coursemode course_mode
ON
	 track_targets.track_id = course_mode.id;

DROP TABLE IF EXISTS ahemphill.user_course_cohorts;
CREATE TABLE IF NOT EXISTS ahemphill.user_course_cohorts AS

SELECT
	cohorts.id AS cohort_id,
	cohorts.name AS cohort_name,
	cohorts.course_id,
	users.user_id
FROM
	lms_read_replica.course_groups_courseusergroup cohorts
JOIN
	lms_read_replica.course_groups_courseusergroup_users users
ON
	cohorts.id = users.courseusergroup_id;

DROP TABLE IF EXISTS ahemphill.bulk_email_user_targets;
CREATE TABLE IF NOT EXISTS ahemphill.bulk_email_user_targets AS

SELECT
	*
FROM
(
	SELECT
		users.date,
		users.user_id,
		users.content_availability_date,
		users.first_verified_enrollment_time,
		users.is_enrolled,
		users.is_verified,
		DATEDIFF('day', users.content_availability_date, email.created_timestamp) AS days_from_content_availability,
		email.email_id,
		email.course_id,
		email.created_timestamp,
		email.target_type,
		email.cohort_id,
		email.mode_slug
	FROM
		ahemphill.bulk_email_targets email
	JOIN
		ahemphill.user_course_enrolls_time users
	ON
		email.course_id = users.course_id
	AND
		DATE(email.created_timestamp) = users.date
	AND
		email.target_type = 'learners'
	AND
		users.is_enrolled = 1

	UNION ALL 

	SELECT
		users.date,
		users.user_id,
		users.content_availability_date,
		users.first_verified_enrollment_time,
		users.is_enrolled,
		users.is_verified,
		DATEDIFF('day', users.content_availability_date, email.created_timestamp) AS days_from_content_availability,
		email.email_id,
		email.course_id,
		email.created_timestamp,
		email.target_type,
		email.cohort_id,
		email.mode_slug
	FROM
		ahemphill.bulk_email_targets email
	JOIN
		ahemphill.user_course_cohorts cohort
	ON
		email.target_type = 'cohort'
	AND
		email.cohort_id = cohort.cohort_id
	JOIN
		ahemphill.user_course_enrolls_time users
	ON
		cohort.user_id = users.user_id
	AND
		cohort.course_id = users.course_id
	AND
		DATE(email.created_timestamp) = users.date

	UNION ALL

	SELECT
		users.date,
		users.user_id,
		users.content_availability_date,
		users.first_verified_enrollment_time,
		users.is_enrolled,
		users.is_verified,
		DATEDIFF('day', users.content_availability_date, email.created_timestamp) AS days_from_content_availability,
		email.email_id,
		email.course_id,
		email.created_timestamp,
		email.target_type,
		email.cohort_id,
		email.mode_slug
	FROM
		ahemphill.bulk_email_targets email
	JOIN
		ahemphill.user_course_enrolls_time users
	ON
		email.course_id = users.course_id
	AND
		DATE(email.created_timestamp) = users.date
	AND
		email.target_type = 'track'
	AND
		email.mode_slug = 'audit'
	AND
		users.is_verified = 0
	AND
		users.is_enrolled = 1

	UNION ALL 

	SELECT
		users.date,
		users.user_id,
		users.content_availability_date,
		users.first_verified_enrollment_time,
		users.is_enrolled,
		users.is_verified,
		DATEDIFF('day', users.content_availability_date, email.created_timestamp) AS days_from_content_availability,
		email.email_id,
		email.course_id,
		email.created_timestamp,
		email.target_type,
		email.cohort_id,
		email.mode_slug
	FROM
		ahemphill.bulk_email_targets email
	JOIN
		ahemphill.user_course_enrolls_time users
	ON
		email.course_id = users.course_id
	AND
		DATE(email.created_timestamp) = users.date
	AND
		email.target_type = 'track'
	AND
		email.mode_slug = 'verified'
	AND
		users.is_verified = 1
	AND
		users.is_enrolled = 1
) a;

DROP TABLE IF EXISTS ahemphill.bulk_email_user_activity_engagement;
CREATE TABLE IF NOT EXISTS ahemphill.bulk_email_user_activity_engagement AS

SELECT 
	DATEDIFF('day', a.date, c.date) AS days_from_email,
	c.date AS absolute_date,
	DATE(a.created_timestamp) AS email_date,
	a.email_id,
	a.user_id,
	a.course_id,
	a.content_availability_date,
	a.first_verified_enrollment_time,
	a.is_enrolled,
	a.is_verified,
	a.days_from_content_availability,
	is_active,
	is_engaged
FROM 
	ahemphill.bulk_email_user_targets a 
JOIN 
	calendar c
ON 
	DATEDIFF('day', a.date, c.date) between -13 and 13
LEFT JOIN 
	activity_engagement_user_daily b
ON 
	a.user_id = b.user_id
AND 
	a.course_id = b.course_id
AND 
	b.date = c.date;


