/*
when users register because of a profed course, track whether they ended up paying for that course
*/

DROP TABLE IF EXISTS ahemphill.acct_activation_dropoff_verif_profed;
CREATE TABLE ahemphill.acct_activation_dropoff_verif_profed AS

SELECT
	CASE WHEN a.user_id IS NULL THEN 'already_have_acct' ELSE 'new_acct' END AS acct_status,
	label,
	partner_short_code,
	c.start_time,
	c.end_time,
	c.enrollment_start_time,
	c.enrollment_end_time,
	COUNT(1) AS num_registrations,
	SUM(CASE WHEN b.user_id IS NOT NULL THEN 1 ELSE 0 END) AS num_enrolls,
	SUM(CASE WHEN b.current_enrollment_mode = 'no-id-professional'  THEN 1 ELSE 0 END) AS num_verifs
FROM
	d_user_course b
LEFT JOIN
(
SELECT 
	date,
	user_id,
	label
	FROM experimental_events_run14.event_records
	where event_type = 'edx.bi.user.account.registered'
	and label IS NOT NULL
	and date >= '2016-07-01'
) a
	ON a.user_id = b.user_id
	AND a.label = b.course_id
LEFT JOIN
	d_course c
	ON a.label = c.course_id
JOIN
	ahemphill.profed_courses d
ON a.label = d.course_id
GROUP BY 
	1,2,3,4,5,6,7;


DROP TABLE IF EXISTS ahemphill.acct_activation_dropoff;
CREATE TABLE ahemphill.acct_activation_dropoff AS

SELECT
	a.user_id,
	a.acct_type,
	a.label AS course_id,
	MAX(track_selection_nav) AS track_selection_nav,
	MIN(track_selection_timestamp) AS track_selection_timestamp,
	MAX(verify_student_nav) AS verify_student_nav,
	MIN(verify_student_timestamp) AS verify_student_timestamp
FROM
(
	SELECT
		a.*,
		CASE WHEN a.user_id IS NOT NULL THEN 'new_acct' ELSE 'old_acct' END as acct_type,
		CASE WHEN b.url LIKE '%course_modes/choose/%' THEN 1 ELSE 0 END AS track_selection_nav,
		CASE WHEN b.url LIKE '%course_modes/choose/%' THEN b.timestamp ELSE NULL END AS track_selection_timestamp,
		CASE WHEN b.url LIKE '%/verify_student/start-flow/%' THEN 1 ELSE 0 END AS verify_student_nav,
		CASE WHEN b.url LIKE '%/verify_student/start-flow/%' THEN b.timestamp ELSE NULL END AS verify_student_timestamp
	FROM
		experimental_events_run14.event_records b		
	LEFT JOIN
	(
		SELECT 
			timestamp,
			date,
			user_id,
			label
		FROM 
			experimental_events_run14.event_records
		WHERE 
			event_type = 'edx.bi.user.account.registered'
			AND label IS NOT NULL
			AND date >= '2016-07-01'
	) a
	ON a.user_id = b.user_id
	AND a.date = b.date
	WHERE
		b.timestamp > a.timestamp
		AND b.event_type = 'page'
) a
GROUP BY 1,2,3;
HAVING
	MAX(verify_student_nav) = 1;
	AND MAX(track_selection_nav) = 1
	AND MIN(track_selection_timestamp) < MIN(verify_student_timestamp);

DROP TABLE IF EXISTS ahemphill.acct_activation_dropoff_verif;
CREATE TABLE ahemphill.acct_activation_dropoff_verif AS

SELECT 
	a.course_id,
	c.partner_short_code,
	COUNT(1) AS cnt_registered,
	SUM(CASE WHEN b.course_id IS NOT NULL THEN 1 ELSE 0 END) AS cnt_enrolled,
	SUM(CASE WHEN b.first_verified_enrollment_time IS NOT NULL THEN 1 ELSE 0 END) AS cnt_verified,
	SUM(CASE WHEN b.first_verified_enrollment_time IS NOT NULL AND DATE(a.verify_student_timestamp) = DATE(b.first_verified_enrollment_time) THEN 1 ELSE 0 END) AS cnt_verified_direct,
	SUM(CASE WHEN b.course_id IS NOT NULL THEN 1 ELSE 0 END)*100.0/COUNT(1) AS enrollment_pct,
	SUM(CASE WHEN b.first_verified_enrollment_time IS NOT NULL THEN 1 ELSE 0 END)*100.0/COUNT(1) AS verification_pct,
	SUM(CASE WHEN b.first_verified_enrollment_time IS NOT NULL AND DATE(a.verify_student_timestamp) = DATE(b.first_verified_enrollment_time) THEN 1 ELSE 0 END)*100.0/COUNT(1) AS direct_verification_pct
FROM
	ahemphill.acct_activation_dropoff a
LEFT JOIN 
	d_user_course b
ON a.course_id = b.course_id
AND a.user_id = b.user_id
LEFT JOIN 
	d_course c
ON a.course_id = c.course_id
GROUP BY
	1,2;

DROP TABLE IF EXISTS ahemphill.subject_table_deduped;
CREATE TABLE ahemphill.subject_table_deduped AS
SELECT
	course_id,
	subject_title
FROM
(
SELECT
    course_id,
    subject_title,
    row_number() OVER (partition by course_id order by random()) AS rank
FROM
    production.d_course_subjects
) a
WHERE
	rank = 1;

DROP TABLE IF EXISTS ahemphill.profed_courses;
CREATE TABLE ahemphill.profed_courses AS
SELECT 
	course_id, 
	SUM(CASE WHEN current_enrollment_mode like '%professional%' then 1 else 0 end) 
FROM
	d_user_course 
GROUP BY
	1
HAVING
	SUM(CASE WHEN current_enrollment_mode like '%professional%' then 1 else 0 end) > 50;

DROP TABLE IF EXISTS ahemphill.acct_activation_dropoff_results;
CREATE TABLE ahemphill.acct_activation_dropoff_results AS
SELECT 
	a.*,
	b.subject_title,
	c.course_seat_price
FROM
(
	SELECT
		label AS course_id,
		partner_short_code,
		num_registrations AS cnt_registered,
		num_verifs AS cnt_enrolled,
		num_verifs AS cnt_verifs,
		num_verifs AS cnt_verifs_direct,
		'prof_ed' AS category
	FROM
		ahemphill.acct_activation_dropoff_verif_profed

	UNION ALL

	SELECT
		course_id,
		partner_short_code,
		cnt_registered,
		cnt_enrolled,
		cnt_verified AS cnt_verifs,
		cnt_verified_direct AS cnt_verifs_direct,
		'non_prof_ed' AS category
	FROM
		ahemphill.acct_activation_dropoff_verif	
) a 
LEFT JOIN 
	ahemphill.subject_table_deduped b
ON a.course_id = b.course_id
LEFT JOIN
	d_course_seat c
ON a.course_id = c.course_id
AND c.course_seat_type = 'verified'
LEFT JOIN
	ahemphill.profed_courses d
ON a.course_id = d.course_id

select * from ahemphill.acct_activation_dropoff_results 
where (cnt_registered > 50 AND partner_short_code != 'edx') OR (cnt_registered > 500 and partner_short_code = 'edx')


/*
for users who click on the verify button on the track selection page
determine whether they are a new or old account
*/

DROP TABLE IF EXISTS ahemphill.acct_activation_verify_attempt;
CREATE TABLE ahemphill.acct_activation_verify_attempt AS

SELECT 
	a.user_id,
	a.acct_type,
	regexp_replace(regexp_replace(a.course_id, '%3A',':'), '%2B','+') AS course_id
FROM
(
	SELECT 
		CAST(user_id AS VARCHAR) AS user_id,
		'new_acct' AS acct_type,
		regexp_substr(path, 'course.*?(?=\/)') AS course_id
	FROM 
		experimental_events_run14.event_records 
	WHERE
		path like '/verify_student/start-flow/%' 
		AND event_type = 'identify'
	GROUP BY
		user_id, 2, 3

	UNION ALL

	SELECT
		CAST(b.user_id AS VARCHAR) AS user_id,
		a.acct_type,
		a.course_id
	FROM
	(
		SELECT 
			user_id,
			'old_acct' AS acct_type,
			regexp_substr(referrer, 'course-.*?(?=\/)') AS course_id
		FROM 
			experimental_events_run14.event_records 
		WHERE
			path = '/basket/' 
			AND referrer like '%course_modes/choose/%'
			AND event_type = 'identify'
		GROUP BY
			user_id, 2, 3
	) a
	JOIN
		d_user b
	ON a.user_id = b.user_username
) a;

/*
determine whether new/old users who click on the verify button end up 
verifying for the course
*/

DROP TABLE IF EXISTS ahemphill.acct_activation_verify_attempt_summary;
CREATE TABLE ahemphill.acct_activation_verify_attempt_summary AS

SELECT 
        a.acct_type,
        a.course_id,
        COUNT(1) AS cnt_verify_button_click,
        COUNT(first_verified_enrollment_time) AS cnt_verifs
FROM 
	d_user_course a
JOIN 
	ahemphill.acct_activation_verify_attempt b
ON a.user_id = b.user_id
AND a.course_id = b.course_id
GROUP BY
	a.acct_type,
	a.course_id;

