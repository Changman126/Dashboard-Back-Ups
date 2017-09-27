--this table looks at how long it took users to verify in a MM course if they enrolled after the course had started

DROP TABLE IF EXISTS ahemphill.mm_verif_after_enroll;
CREATE TABLE ahemphill.mm_verif_after_enroll AS

SELECT
	a.user_id,
	a.course_id,
	b.program_title,
	b.catalog_course_title,
	date(first_verified_enrollment_time) AS date_verified,
	datediff('day',first_enrollment_time, first_verified_enrollment_time) AS diff_verify_to_enroll
FROM
	d_user_course a
JOIN
	d_program_course b
ON a.course_id = b.course_id
AND b.program_type = 'MicroMasters'
JOIN
	d_course c
ON a.course_id = c.course_id
AND a.first_enrollment_time >= c.start_time
WHERE
	first_verified_enrollment_time is not null;

--this table determines whether a user watched a video or attempted a problem prior to verification

DROP TABLE IF EXISTS ahemphill.mm_verif_after_enroll_days_active;
CREATE TABLE ahemphill.mm_verif_after_enroll_days_active AS

SELECT
	a.user_id,
	a.course_id,
	a.program_title,
	a.catalog_course_title,
	a.date_verified,
	a.diff_verify_to_enroll,
	COUNT(DISTINCT b.date) AS days_w_activity,
	SUM(CASE WHEN b.activity_type IN ('ATTEMPTED_PROBLEM') THEN 1 ELSE 0 END) AS days_w_attempted_problem,
	SUM(CASE WHEN b.activity_type IN ('PLAYED_VIDEO') THEN 1 ELSE 0 END) AS days_w_video
FROM
	ahemphill.mm_verif_after_enroll  a
JOIN
	f_user_activity b
ON a.course_id = b.course_id
AND a.user_id = b.user_id
AND b.date <= a.date_verified
GROUP BY
	1,2,3,4,5,6;

--this table looks at whether VTR is different depending on how far before a course start the user enrolled

DROP TABLE IF EXISTS ahemphill.mm_enroll_cohort_vtr;
CREATE TABLE ahemphill.mm_enroll_cohort_vtr AS

SELECT
	a.course_id, 
	CASE 
	WHEN DATEDIFF('day',c.start_time, a.first_enrollment_time) BETWEEN -60 and -30 then '-60 to -30'
	WHEN DATEDIFF('day',c.start_time, a.first_enrollment_time) BETWEEN -30 and -14 then '-30 to -14'
	WHEN DATEDIFF('day',c.start_time, a.first_enrollment_time) BETWEEN -14 and -7 then '-14 to -7'
	WHEN DATEDIFF('day',c.start_time, a.first_enrollment_time) BETWEEN -7 and 0 then '-7 to 0'
	WHEN DATEDIFF('day',c.start_time, a.first_enrollment_time) BETWEEN 0 and 7 then '0 to 7'
	WHEN DATEDIFF('day',c.start_time, a.first_enrollment_time) BETWEEN 7 and 14 then '7 to 14'
	WHEN DATEDIFF('day',c.start_time, a.first_enrollment_time) BETWEEN 14 and 30 then '14 to 30'
	ELSE '30 to 60'
	END AS enrollment_cohort, 
	COUNT(1) AS num_enrolls, 
	COUNT(first_verified_enrollment_time) AS num_verifs
FROM d_user_course a
JOIN 
	d_program_course b
ON a.course_id = b.course_id
AND b.program_type = 'MicroMasters'
JOIN 
	d_course c
ON a.course_id = c.course_id
WHERE 
	datediff('day',c.start_time, a.first_enrollment_time) BETWEEN -60 and 60
GROUP BY
	1,2;

--this table looks at whether activity level is different depending on how far before a course start the user enrolled

DROP TABLE IF EXISTS ahemphill.mm_enroll_cohort_activity;
CREATE TABLE ahemphill.mm_enroll_cohort_activity AS

SELECT
	a.user_id,
	a.course_id,
	b.program_title,
	c.catalog_course_title,
	case 
	WHEN DATEDIFF('day',c.start_time, a.first_enrollment_time) BETWEEN -120 and -90 then '-120 to -90'
	WHEN DATEDIFF('day',c.start_time, a.first_enrollment_time) BETWEEN -90 and -60 then '-90 to -60'
	WHEN DATEDIFF('day',c.start_time, a.first_enrollment_time) BETWEEN -60 and -30 then '-60 to -30'
	WHEN DATEDIFF('day',c.start_time, a.first_enrollment_time) BETWEEN -30 and -14 then '-30 to -14'
	WHEN DATEDIFF('day',c.start_time, a.first_enrollment_time) BETWEEN -14 and -7 then '-14 to -7'
	WHEN DATEDIFF('day',c.start_time, a.first_enrollment_time) BETWEEN -7 and 0 then '-7 to 0'
	WHEN DATEDIFF('day',c.start_time, a.first_enrollment_time) BETWEEN 0 and 7 then '0 to 7'
	WHEN DATEDIFF('day',c.start_time, a.first_enrollment_time) BETWEEN 7 and 14 then '7 to 14'
	WHEN DATEDIFF('day',c.start_time, a.first_enrollment_time) BETWEEN 14 and 30 then '14 to 30'
	ELSE '30 to 60'
	END AS enrollment_cohort,
	COUNT(DISTINCT d.date) AS days_w_activity,
	SUM(CASE WHEN d.activity_type IN ('ATTEMPTED_PROBLEM') THEN 1 ELSE 0 END) AS days_w_attempted_problem,
	SUM(CASE WHEN d.activity_type IN ('PLAYED_VIDEO') THEN 1 ELSE 0 END) AS days_w_video
FROM 
	d_user_course a
JOIN 
	d_program_course b
ON a.course_id = b.course_id
AND b.program_type = 'MicroMasters'
JOIN 
	d_course c
ON a.course_id = c.course_id
LEFT JOIN
	f_user_activity d
ON a.course_id = d.course_id
AND a.user_id = d.user_id
AND d.date >= date(c.start_time)
WHERE
	datediff('day',c.start_time, a.first_enrollment_time) BETWEEN -120 and 60
GROUP BY
	1,2,3,4,5;

DROP TABLE IF EXISTS ahemphill.mm_enroll_cohort_activity_summary;
CREATE TABLE ahemphill.mm_enroll_cohort_activity_summary AS

SELECT 
	course_id, 
	program_title, 
	enrollment_cohort,
	COUNT(1) AS cnt_enrolls,
	SUM(CASE WHEN (days_w_attempted_problem != 0 OR days_w_video != 0) 
	THEN 1 ELSE 0 END) *100.0/count(1) AS pct_days_active
FROM 
	ahemphill.mm_enroll_cohort_activity
GROUP BY
	1,2,3;