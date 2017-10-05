DROP TABLE IF EXISTS tmp_enterprise_enrollment;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_enterprise_enrollment ON COMMIT PRESERVE ROWS AS

SELECT
	DISTINCT
	enroll.enterprise_customer_user_id AS enterprise_user_id,
	enterprise_user.user_id AS lms_user_id,
	enroll.created AS enrollment_created_timestamp,
	enroll.modified AS enrollment_modified_timestamp,
	consent.granted AS consent_granted,
	enroll.course_id AS course_id,
	enterprise.uuid AS enterprise_id,
	enterprise.name AS enterprise_name,
	enterprise.active AS enterprise_active,
	enterprise.site_id AS enterprise_site_id,
	enterprise.catalog AS enterprise_catalog,
	enterprise.enable_data_sharing_consent AS enterprise_enable_data_sharing_consent,
	enterprise.enforce_data_sharing_consent AS enterprise_enforce_data_sharing_consent
FROM 
	lms_read_replica.enterprise_enterprisecourseenrollment enroll
RIGHT OUTER JOIN
	lms_read_replica.enterprise_enterprisecustomeruser enterprise_user
ON 
	enroll.enterprise_customer_user_id = enterprise_user.id
RIGHT OUTER JOIN
	lms_read_replica.enterprise_enterprisecustomer enterprise
ON 
	enterprise_user.enterprise_customer_id = enterprise.uuid
LEFT JOIN
  production.d_user d_user
ON
  enterprise_user.user_id = d_user.user_id
LEFT JOIN
  lms_read_replica.consent_datasharingconsent consent
ON
  d_user.user_username = consent.username
AND
  enroll.course_id = consent.course_id;

DROP TABLE IF EXISTS enterprise_enrollment;
CREATE TABLE IF NOT EXISTS enterprise_enrollment AS

SELECT
	enterprise.enterprise_user_id,
	enterprise.lms_user_id,
	enterprise.enrollment_created_timestamp,
	enterprise.enrollment_modified_timestamp,
	enterprise.consent_granted,
	enterprise.course_id,
	enterprise.enterprise_id,
	enterprise.enterprise_name,
	enterprise.enterprise_active,
	enterprise.enterprise_site_id,
	enterprise.enterprise_catalog,
	enterprise.enterprise_enable_data_sharing_consent,
	enterprise.enterprise_enforce_data_sharing_consent,
	DATE(d_user.user_account_creation_time) AS user_account_creation_date,
	d_user.user_email,
	d_user.user_username,
	YEAR(CURRENT_DATE() - d_user.user_year_of_birth) AS user_age,
	d_user.user_level_of_education,
	d_user.user_gender,
	d_user.user_last_location_country_code AS user_country_code,
	d_country.country_name,
	cert.has_passed,
	activity.latest_date AS last_activity_date,
	course.marketing_url AS course_about_page_url,
	user_course.current_enrollment_mode AS user_current_enrollment_mode
FROM
	tmp_enterprise_enrollment enterprise
LEFT JOIN
	production.d_user d_user
ON
	enterprise.lms_user_id = d_user.user_id
LEFT JOIN
	production.d_country d_country
ON
	d_user.user_last_location_country_code = d_country.user_last_location_country_code
LEFT JOIN
	production.d_user_course_certificate cert
ON
	enterprise.lms_user_id = cert.user_id
AND
	enterprise.course_id = cert.course_id
LEFT JOIN
	(
		SELECT
			user_id,
			course_id,
			MAX(date) AS latest_date
		FROM
			production.f_user_activity
		GROUP BY 
			user_id,
			course_id
	) activity
ON
	enterprise.lms_user_id = activity.user_id
AND
	enterprise.course_id = activity.course_id
LEFT JOIN
	production.d_course course
ON
	enterprise.course_id = course.course_id
LEFT JOIN
	production.d_user_course user_course
ON
	enterprise.course_id = user_course.course_id
AND
	enterprise.lms_user_id = user_course.user_id;

DROP TABLE IF EXISTS enterprise_summary;
CREATE TABLE IF NOT EXISTS enterprise_summary AS

SELECT
	enterprise_enrollment.enterprise_name,
	COUNT(DISTINCT enterprise_enrollment.lms_user_id) AS cnt_distinct_users,
	COUNT(enterprise_enrollment.enrollment_created_timestamp) AS cnt_enrollments,
	SUM(
		CASE
			WHEN enterprise_enrollment.user_current_enrollment_mode = 'verified' THEN 1 
			ELSE 0
		END
		) AS cnt_verifications,
	SUM(
		CASE
			WHEN enterprise_enrollment.has_passed = 1 THEN 1 
			ELSE 0
		END
		) AS cnt_completions,
	COUNT(DISTINCT enterprise_enrollment.course_id) AS cnt_distinct_course_runs,
	COUNT(DISTINCT course_master.course_number) AS cnt_distinct_courses,
	COUNT(DISTINCT activity.user_id) AS cnt_active_users,
	SUM(activity.cnt_video_activities) AS cnt_video_activities,
	SUM(
		CASE
			WHEN watched_video = 1 THEN 1 
			ELSE 0
		END
		) AS cnt_watched_videos,
	SUM(activity.cnt_problem_activities) AS cnt_problem_activities,
	SUM(
		CASE
			WHEN tried_problem = 1 THEN 1 
			ELSE 0
		END
		) AS cnt_tried_problem,
	SUM(activity.cnt_forum_activities) AS cnt_forum_activities,
	SUM(
		CASE
			WHEN discussion_participation = 1 THEN 1 
			ELSE 0
		END
		) AS discussion_participation
FROM
	business_intelligence.enterprise_enrollment enterprise_enrollment
LEFT JOIN
	business_intelligence.course_master course_master
ON
	enterprise_enrollment.course_id = course_master.course_id
LEFT JOIN
	(
		SELECT
			user_id,
			course_id,
			SUM(cnt_video_activity) AS cnt_video_activities,
			CASE
				WHEN SUM(cnt_video_activity) > 0 THEN 1 
				ELSE 0
			END AS watched_video,
			SUM(cnt_problem_activity) AS cnt_problem_activities,
			CASE
				WHEN SUM(cnt_problem_activity) > 0 THEN 1 
				ELSE 0
			END AS tried_problem,
			SUM(cnt_forum_activity) AS cnt_forum_activities,
			CASE
				WHEN SUM(cnt_forum_activity) > 0 THEN 1 
				ELSE 0
			END AS discussion_participation
		FROM
			business_intelligence.user_activity_engagement_daily
		WHERE
			is_active = 1
		GROUP BY
			user_id, course_id
	) activity
ON
	enterprise_enrollment.lms_user_id = activity.user_id
AND
	enterprise_enrollment.course_id = activity.course_id
GROUP BY
	enterprise_enrollment.enterprise_name;

DROP TABLE IF EXISTS user_enterprise;
CREATE TABLE IF NOT EXISTS user_enterprise AS

SELECT
	enterprise_enrollment.enterprise_name,
	enterprise_enrollment.user_username,
	enterprise_enrollment.user_email,
	enterprise_enrollment.lms_user_id,
	enterprise_enrollment.user_country_code,
	enterprise_enrollment.user_gender,
	enterprise_enrollment.user_account_creation_date,
	enterprise_enrollment.enterprise_enable_data_sharing_consent,
	enterprise_enrollment.enrollment_created_timestamp,
	enterprise_enrollment.course_id,
	course_master.course_name,
	course_master.program_title,
	course_master.course_start_date,
	course_master.course_end_date,
	enterprise_enrollment.has_passed,
	enterprise_enrollment.last_activity_date,
	activity.cnt_video_activities,
	activity.cnt_problem_activities,
	activity.cnt_forum_activities
FROM
	business_intelligence.enterprise_enrollment enterprise_enrollment
LEFT JOIN
	business_intelligence.course_master course_master
ON
	enterprise_enrollment.course_id = course_master.course_id
LEFT JOIN
	(
		SELECT
			user_id,
			course_id,
			SUM(cnt_video_activity) AS cnt_video_activities,
			CASE
				WHEN SUM(cnt_video_activity) > 0 THEN 1 
				ELSE 0
			END AS watched_video,
			SUM(cnt_problem_activity) AS cnt_problem_activities,
			CASE
				WHEN SUM(cnt_problem_activity) > 0 THEN 1 
				ELSE 0
			END AS tried_problem,
			SUM(cnt_forum_activity) AS cnt_forum_activities,
			CASE
				WHEN SUM(cnt_forum_activity) > 0 THEN 1 
				ELSE 0
			END AS discussion_participation
		FROM
			business_intelligence.user_activity_engagement_daily
		WHERE
			is_active = 1
		GROUP BY
			1, 2
	) activity
ON
	enterprise_enrollment.lms_user_id = activity.user_id
AND
	enterprise_enrollment.course_id = activity.course_id;	

DROP TABLE IF EXISTS tmp_enterprise_enrollment;

GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO standard;
GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO analyst;
