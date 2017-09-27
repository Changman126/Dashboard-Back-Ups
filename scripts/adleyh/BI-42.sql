DROP TABLE IF EXISTS ahemphill.subjects_deduped;
CREATE TABLE IF NOT EXISTS ahemphill.subjects_deduped AS

SELECT
    DISTINCT a.course_id,
    b.subject_title
FROM
    production.d_user_course a
JOIN
(
    SELECT
        course_id,
        subject_title,
        row_number() OVER (partition by course_id order by random()) AS rank
    FROM
        production.d_course_subjects
) b
ON a.course_id = b.course_id
WHERE
    b.rank = 1;


DROP TABLE IF EXISTS ahemphill.user_enroll_date_groups;
CREATE TABLE IF NOT EXISTS ahemphill.user_enroll_date_groups AS

SELECT
	a.user_id,
	a.course_id,
	b.course_start_date,
	a.first_enrollment_time,
	a.first_verified_enrollment_time,
	DATEDIFF('day',  b.course_start_date, a.first_enrollment_time) AS enroll_group,
	b.course_seat_upgrade_deadline,
	b.pacing_type,
	b.level_type,
	b.org_id,
	b.program_type,
	b.program_title,
	b.subject_title,
	b.course_announce_date,
	b.announce_date_start_date_delta

FROM 
	d_user_course a
JOIN
	ahemphill.course_announce_date_groups b
ON a.course_id = b.course_id
AND b.course_start_date >= '2016-01-01';

DROP TABLE IF EXISTS ahemphill.user_activity_summary;
CREATE TABLE IF NOT EXISTS ahemphill.user_activity_summary AS

SELECT
	user_id,
	course_id,
	MIN(date) AS first_activity_date
FROM 
	f_user_activity
WHERE
	activity_type IN ('ATTEMPTED_PROBLEM', 'PLAYED_VIDEO')
GROUP BY
	user_id,
	course_id;

DROP TABLE IF EXISTS ahemphill.user_enroll_date_groups_vtr_activity;
CREATE TABLE IF NOT EXISTS ahemphill.user_enroll_date_groups_vtr_activity AS

SELECT
	a.course_id,
	a.course_start_date,
	a.course_seat_upgrade_deadline,
	a.pacing_type,
	a.level_type,
	a.org_id,
	a.program_type,
	a.program_title,
	a.subject_title,
	a.course_announce_date,
	a.announce_date_start_date_delta,
	CASE 
	WHEN enroll_group <= -120 THEN '<-120'
	WHEN enroll_group BETWEEN -120 AND -90 THEN '-90 to -120'
	WHEN enroll_group BETWEEN -90 AND -60 THEN '-60 to -90'
	WHEN enroll_group BETWEEN -60 AND -30 THEN '-30 to -60'
	WHEN enroll_group BETWEEN -30 AND 0 THEN '0 to -30'
	WHEN enroll_group BETWEEN 0 AND 30 THEN '0 to 30'
	WHEN enroll_group BETWEEN 30 AND 60 THEN '30 to 60'
	WHEN enroll_group BETWEEN 60 AND 90 THEN '60 to 90'
	WHEN enroll_group BETWEEN 90 AND 120 THEN '90 to 120'
	WHEN enroll_group >= 120 THEN '>120'
	END AS enroll_group,
	COUNT(1) AS cnt_enrolls,
	SUM(CASE WHEN date(a.first_enrollment_time) <= date(c.course_seat_upgrade_deadline)  THEN 1 ELSE 0 END) AS cnt_enrolls_vtr,
	COUNT(a.first_verified_enrollment_time) AS cnt_verifs,
	SUM(CASE WHEN b.first_activity_date >= a.first_enrollment_time THEN 1 ELSE 0 END) AS cnt_consumed_content
FROM 
	ahemphill.user_enroll_date_groups a
LEFT JOIN
	ahemphill.user_activity_summary b
ON a.course_id = b.course_id
AND a.user_id = b.user_id
JOIN
	d_course_seat c
ON a.course_id = c.course_id
AND c.course_seat_type = 'verified'
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12;





















DROP TABLE IF EXISTS ahemphill.course_announce_date_groups;
CREATE TABLE IF NOT EXISTS ahemphill.course_announce_date_groups AS

SELECT
	a.course_id,
	b.start_time AS course_start_date,
	c.course_seat_upgrade_deadline,
	b.pacing_type,
	b.level_type,
	b.org_id,
	d.program_type,
	d.program_title,
	e.subject_title,
	a.course_announce_date,
	DATEDIFF('day', a.course_announce_date, b.start_time) AS announce_date_start_date_delta
FROM
	(
		SELECT
			course_id,
			MIN(first_enrollment_time) AS course_announce_date
		FROM
			d_user_course
		GROUP BY
			course_id
	) a
JOIN
	d_course b
ON a.course_id = b.course_id
JOIN
	d_course_seat c
ON a.course_id = c.course_id
AND c.course_seat_type = 'verified'
LEFT JOIN
	d_program_course d
ON a.course_id = d.course_id
LEFT JOIN
	ahemphill.subjects_deduped e
ON a.course_id = e.course_id;


DROP TABLE IF EXISTS ahemphill.course_announce_date_vtr;
CREATE TABLE IF NOT EXISTS ahemphill.course_announce_date_vtr AS

SELECT
	a.*,
	SUM(CASE WHEN date(b.first_enrollment_time) <= date(a.course_seat_upgrade_deadline)  THEN 1 ELSE 0 END) AS cnt_enrolls,
	SUM(CASE WHEN b.first_verified_enrollment_time IS NOT NULL THEN 1 ELSE 0 END) AS cnt_verifs
FROM
	d_user_course b
JOIN
	ahemphill.course_announce_date a
ON a.course_id = b.course_id
GROUP BY 1,2,3,4,5,6,7,8,9,10,11;

DROP TABLE IF EXISTS ahemphill.enroll_group_vtr;
CREATE TABLE ahemphill.enroll_group_vtr AS

SELECT
	a.course_id, 
	CASE 
	WHEN DATEDIFF('day', c.course_start_date, a.first_enrollment_time) BETWEEN -60 and -30 then '-60 to -30'
	WHEN DATEDIFF('day', c.course_start_date, a.first_enrollment_time) BETWEEN -30 and -14 then '-30 to -14'
	WHEN DATEDIFF('day', c.course_start_date, a.first_enrollment_time) BETWEEN -14 and -7 then '-14 to -7'
	WHEN DATEDIFF('day', c.course_start_date, a.first_enrollment_time) BETWEEN -7 and 0 then '-7 to 0'
	WHEN DATEDIFF('day', c.course_start_date, a.first_enrollment_time) BETWEEN 0 and 7 then '0 to 7'
	WHEN DATEDIFF('day', c.course_start_date, a.first_enrollment_time) BETWEEN 7 and 14 then '7 to 14'
	WHEN DATEDIFF('day', c.course_start_date, a.first_enrollment_time) BETWEEN 14 and 30 then '14 to 30'
	ELSE '30 to 60'
	END AS enrollment_group, 
	COUNT(1) AS num_enrolls,
	SUM(CASE WHEN date(a.first_enrollment_time) <= date(c.course_seat_upgrade_deadline) THEN 1 ELSE 0 END) AS cnt_enrolls_vtr,
	COUNT(first_verified_enrollment_time) AS num_verifs
FROM d_user_course a
JOIN 
	ahemphill.course_announce_date c
ON a.course_id = c.course_id
WHERE 
	datediff('day', c.course_start_date, a.first_enrollment_time) BETWEEN -60 and 60
GROUP BY
	1,2;



