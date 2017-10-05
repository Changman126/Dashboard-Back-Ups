--Mapping Tables for Course Metadata including Course Subjects, Dates, etc.
-- Course Deduped Subject Table
DROP TABLE IF EXISTS course_subject_deduped;
CREATE TABLE IF NOT EXISTS course_subject_deduped AS
SELECT
	catalog_course,
	subject_title AS subject_name,
	rank
FROM
	(
		SELECT
			DISTINCT a.catalog_course,
			b.subject_title,
			ROW_NUMBER() OVER (PARTITION BY catalog_course ORDER BY subject_title asc) AS rank
		FROM 
			production.d_course a
		LEFT JOIN 
			production.d_course_subjects b
		ON 
			a.course_id = b.course_id
	) s
WHERE
	rank = 1;
SELECT ANALYZE_STATISTICS('course_subject_deduped')
;

--Master Course Table
DROP TABLE IF EXISTS course_master;
CREATE TABLE IF NOT EXISTS course_master AS
SELECT
	DISTINCT course.course_id,
	sub.subject_name AS course_subject,
	CASE
		WHEN course.partner_short_code = 'edx' THEN 0
		ELSE 1
	END AS is_WL,
	course.catalog_course_title AS course_name,
	DATE(course.start_time) AS course_start_date,
	DATE(course.end_time) AS course_end_date,
	DATE(course.announcement_time) AS course_announcement_date,
	DATE(course.enrollment_start_time) AS course_enrollment_start_date,
	DATE(course.enrollment_end_time) AS course_enrollment_end_date,
	udate.course_seat_price,
	course.content_language,
	course.pacing_type,
	course.level_type,
	DATE(udate.course_seat_upgrade_deadline) AS course_verification_end_date,
	CASE
		WHEN DATE(getdate()) BETWEEN DATE(start_time) AND DATE(end_time) THEN 1
		ELSE 0
	END AS is_active,
	CASE
		WHEN DATE(udate.course_seat_upgrade_deadline) <= DATE(getdate()) THEN 1
		ELSE 0
	END AS has_verification_deadline_passed,
	DATEDIFF(DAY, getdate(), start_time) AS days_to_course_start,
	DATEDIFF(DAY, getdate(), end_time) AS days_to_course_end,
	DATEDIFF(DAY, getdate(), udate.course_seat_upgrade_deadline) AS days_to_verification_deadline,
	course.catalog_course AS course_number,
	crn.course_run_number,
	course.org_id AS course_partner,
	course.marketing_url AS course_about_url,
	course.reporting_type AS course_reporting_type,
       COALESCE(bpc.program_type,'Non-Program') AS program_type,
       COALESCE(bpc.program_title,'Non-Program') AS program_title,
       bpc.program_slot_number,
       bpc.former_xs AS former_xseries
FROM
	production.d_course course
LEFT JOIN
	business_intelligence.course_subject_deduped sub
ON
	course.catalog_course = sub.catalog_course
LEFT JOIN
       finance.base_program_courses bpc
ON
       course.course_id = bpc.course_id
LEFT JOIN
	(
			SELECT
				course_id,
				MAX(course_seat_upgrade_deadline) AS course_seat_upgrade_deadline,
				course_seat_price
			FROM
				production.d_course_seat
			WHERE
				course_seat_type IN
			(
				'verified',
				'no-id-professional',
				'professional'
			)
			GROUP BY
				course_id,
				course_seat_price	
	) udate
ON
	course.course_id = udate.course_id
LEFT JOIN
	(
		SELECT 
			catalog_course,
			course_id,
			row_number() OVER (PARTITION BY catalog_course ORDER BY start_time) AS course_run_number
		FROM
			production.d_course	
	) crn
ON
	course.course_id = crn.course_id;	
SELECT ANALYZE_STATISTICS('course_master')
;

--Course Relative Date Mapping
DROP TABLE IF EXISTS course_date_relative_mapping;
CREATE TABLE IF NOT EXISTS course_date_relative_mapping AS
SELECT 
	course.course_id,
	DATE(getdate()) AS date_absolute,
	DATE(start_time) AS course_start_absolute,
	DATE(end_time) AS course_end_absolute,
	DATE(course_seat_upgrade_deadline) AS course_seat_upgrade_deadline_absolute,
	DATEDIFF(DAY, start_time, getdate()) AS course_start_date_relative,
	DATEDIFF(DAY, end_time, getdate()) AS course_end_date_relative,
	DATEDIFF(DAY, course_seat_upgrade_deadline, getdate()) AS course_seat_upgrade_deadline_relative
FROM 
	production.d_course course
LEFT JOIN
	(
		SELECT
			course_id,
			MAX(course_seat_upgrade_deadline) AS course_seat_upgrade_deadline
		FROM
			production.d_course_seat
		WHERE
			course_seat_type = 'verified'
		AND 
			course_seat_upgrade_deadline IS NOT NULL
		GROUP BY
			course_id	
	) udate
ON
	course.course_id = udate.course_id;
SELECT ANALYZE_STATISTICS('course_date_relative_mapping')
;

GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO standard;
GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO analyst;