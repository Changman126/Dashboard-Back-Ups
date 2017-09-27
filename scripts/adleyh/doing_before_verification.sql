SELECT
	a.user_id,
	a.course_id,
	a.current_enrollment_mode,
	COUNT(DISTINCT b.date) AS unique_days_engaged,
	SUM(CASE WHEN activity_type = 'PLAYED_VIDEO' THEN 1 ELSE 0 END) AS unique_days_video,
	SUM(CASE WHEN activity_type = 'PLAYED_VIDEO' THEN number_of_activities ELSE 0 END) AS unique_activities_video,
	SUM(CASE WHEN activity_type = 'ATTEMPTED_PROBLEM' THEN 1 ELSE 0 END) AS unique_days_problem,
	SUM(CASE WHEN activity_type = 'ATTEMPTED_PROBLEM' THEN number_of_activities ELSE 0 END) AS unique_activities_problem,
	SUM(CASE WHEN activity_type = 'POSTED_FORUM' THEN 1 ELSE 0 END) AS unique_days_forum,
	SUM(CASE WHEN activity_type = 'POSTED_FORUM' THEN number_of_activities ELSE 0 END) AS unique_activities_forum
FROM 
	production.d_user_course a 
JOIN
	business_intelligence.user_content_availability_date c
ON
	a.user_id = c.user_id
AND
	a.course_id = c.course_id
JOIN 
	production.f_user_activity b
ON 
	a.user_id = b.user_id
AND 
	a.course_id = b.course_id
AND 
	a.first_verified_enrollment_time IS NOT NULL
AND 
	DATEDIFF('day',  DATE(b.date),  DATE(c.content_availability_date)) BETWEEN 1 AND 6
AND 
	b.activity_type != 'ACTIVE'
GROUP BY 1,2,3;


---

DROP TABLE IF EXISTS ahemphill.p_verify_model;
CREATE TABLE IF NOT EXISTS ahemphill.p_verify_model AS 

SELECT
	*
FROM
(
	SELECT 
		a.*,
		b.first_enrollment_time,
		b.first_verified_enrollment_time,
		CASE WHEN DATE(b.first_verified_enrollment_time) <= DATE(a.date) THEN 1 ELSE 0 END AS has_verified,
		rank() over (partition by a.user_id, a.course_id order by date asc) AS days_from_content_availability
	FROM 
		business_intelligence.user_activity_engagement_daily a 
	JOIN 
		production.d_user_course b
	ON
		a.user_id = b.user_id
	AND
		a.course_id = b.course_id
	AND
		a.week IN ('week_1', 'week_2')
) a
WHERE
	has_verified = 0 
	OR
	DATE(first_verified_enrollment_time) = DATE(date);

DROP TABLE IF EXISTS ahemphill.p_verify_model_prior_completions;
CREATE TABLE IF NOT EXISTS ahemphill.p_verify_model_prior_completions AS 

SELECT
	a.user_id,
	a.course_id,
	SUM(has_passed) AS cnt_prior_passes
FROM
	ahemphill.p_verify_model a
LEFT JOIN
(
	SELECT
		d_user_course.user_id,
		d_user_course.course_id,
		first_enrollment_time,
		CASE WHEN passed_timestamp IS NOT NULL THEN 1 ELSE 0 END AS has_passed
	FROM
		production.d_user_course d_user_course
	LEFT JOIN
		business_intelligence.course_completion_user comp
	ON
		d_user_course.user_id = comp.user_id
	AND
		d_user_course.course_id = comp.course_id
) comp
ON
	a.user_id = comp.user_id
AND
	a.first_enrollment_time > comp.first_enrollment_time
GROUP BY
	a.user_id,
	a.course_id;

DROP TABLE IF EXISTS ahemphill.p_verify_model_prior_enrolls_verifs;
CREATE TABLE IF NOT EXISTS ahemphill.p_verify_model_prior_enrolls_verifs AS 

SELECT
	a.user_id,
	a.course_id,
	COUNT(1) AS cnt_prior_enrolls,
    SUM(CASE WHEN year(d_user_course.first_enrollment_time) = '2017' THEN 1 ELSE 0 END) as cnt_2017_enrolls,
    SUM(CASE WHEN year(d_user_course.first_enrollment_time) = '2016' THEN 1 ELSE 0 END) as cnt_2016_enrolls,
    SUM(CASE WHEN year(d_user_course.first_enrollment_time) = '2015' THEN 1 ELSE 0 END) as cnt_2015_enrolls,
    COUNT(d_user_course.first_verified_enrollment_time) AS cnt_prior_verifs,
    SUM(CASE WHEN year(d_user_course.first_verified_enrollment_time) = '2016' THEN 1 ELSE 0 END) as cnt_2017_verifs,
    SUM(CASE WHEN year(d_user_course.first_verified_enrollment_time) = '2016' THEN 1 ELSE 0 END) as cnt_2016_verifs,
    SUM(CASE WHEN year(d_user_course.first_verified_enrollment_time) = '2015' THEN 1 ELSE 0 END) as cnt_2015_verifs
FROM
	ahemphill.p_verify_model a
LEFT JOIN
	production.d_user_course d_user_course
ON
	a.user_id = d_user_course.user_id
AND
	a.first_enrollment_time > d_user_course.first_enrollment_time
GROUP BY
	a.user_id,
	a.course_id;

DROP TABLE IF EXISTS ahemphill.p_verify_model_master;
CREATE TABLE IF NOT EXISTS ahemphill.p_verify_model_master AS 
SELECT
	a.*,
	b.pacing_type,
	b.course_subject,
	b.course_run_number,
	b.course_partner,
	b.course_seat_price,
	stats_time.cum_sum_course_vtr,
	DATEDIFF('day', a.date, b.course_verification_end_date) AS days_until_verification_deadline,
	b.level_type,
	d_user.user_year_of_birth,
    d_user.user_level_of_education,
    d_user.user_gender,
    d_user.user_last_location_country_code,
    year(d_user.user_account_creation_time) AS year_registered,
    COALESCE(prior_passes.cnt_prior_passes, 0) AS cnt_prior_passes,
	COALESCE(prior_enrolls_verifs.cnt_prior_enrolls, 0) AS cnt_prior_enrolls,
	COALESCE(prior_enrolls_verifs.cnt_2017_enrolls, 0) AS cnt_2017_enrolls,
	COALESCE(prior_enrolls_verifs.cnt_2016_enrolls, 0) AS cnt_2016_enrolls,
	COALESCE(prior_enrolls_verifs.cnt_2015_enrolls, 0) AS cnt_2015_enrolls,
	COALESCE(prior_enrolls_verifs.cnt_prior_verifs, 0) AS cnt_prior_verifs,
	COALESCE(prior_enrolls_verifs.cnt_2017_verifs, 0) AS cnt_2017_verifs,
	COALESCE(prior_enrolls_verifs.cnt_2016_verifs, 0) AS cnt_2016_verifs,
	COALESCE(prior_enrolls_verifs.cnt_2015_verifs, 0) AS cnt_2015_verifs,
	SUM(a.is_active) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_is_active, 
	SUM(cnt_active_activity) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_cnt_active_activity, 
	SUM(is_engaged) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_is_engaged, 
	SUM(cnt_engaged_activity) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_cnt_engaged_activity,
	SUM(is_engaged_video) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_is_engaged_video, 
	SUM(cnt_video_activity) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_cnt_video_activity, 
	SUM(is_engaged_problem) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_is_engaged_problem, 
	SUM(cnt_problem_activity) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_cnt_problem_activity, 
	SUM(is_engaged_forum) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_is_engaged_forum,
	SUM(cnt_forum_activity) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_cnt_forum_activity
FROM
	ahemphill.p_verify_model a
JOIN
	business_intelligence.course_master b
ON
	a.course_id = b.course_id
JOIN
	ahemphill.p_verify_model_prior_enrolls_verifs prior_enrolls_verifs
ON
	a.user_id = prior_enrolls_verifs.user_id
AND
	a.course_id = prior_enrolls_verifs.course_id
JOIN 
    production.d_user d_user
ON 
    a.user_id = d_user.user_id
JOIN
	ahemphill.p_verify_model_prior_completions prior_passes
ON 
    a.user_id = prior_passes.user_id
AND
	a.course_id = prior_passes.course_id
JOIN
	business_intelligence.course_stats_time stats_time
ON
	a.course_id = stats_time.course_id
AND
    a.date = stats_time.date
;

---


SELECT 
	* 
FROM 
(
	SELECT
		CASE 
			WHEN cumulative_cnt_video_activity = 0 THEN 'no_activity'
			WHEN cumulative_cnt_video_activity between 1 and 5 THEN '1-5'
			WHEN cumulative_cnt_video_activity between 6 and 10 THEN '6-10'
			WHEN cumulative_cnt_video_activity >10  THEN '>10'
		END,
		'video' AS category,
		SUM(has_verified) * 100.0/COUNT(1) AS p_verify,
		COUNT(1) AS cnt_users
	FROM 
		ahemphill.p_verify_model_master
	WHERE 
		week IN ('week_1')
	GROUP BY
		1

	UNION ALL 

	SELECT
		CASE 
			WHEN cumulative_cnt_problem_activity = 0 THEN 'no_activity'
			WHEN cumulative_cnt_problem_activity between 1 and 5 THEN '1-5'
			WHEN cumulative_cnt_problem_activity between 6 and 10 THEN '6-10'
			WHEN cumulative_cnt_problem_activity >10  THEN '>10'
		END,
		'problem' AS category,
		SUM(has_verified) * 100.0/COUNT(1) AS p_verify,
		COUNT(1) AS cnt_users
	FROM 
		ahemphill.p_verify_model_master
	WHERE 
		week IN ('week_1')
	GROUP BY
		1

	UNION ALL

	SELECT
		CASE 
			WHEN cumulative_cnt_forum_activity = 0 THEN 'no_activity'
			WHEN cumulative_cnt_forum_activity between 1 and 5 THEN '1-5'
			WHEN cumulative_cnt_forum_activity between 6 and 10 THEN '6-10'
			WHEN cumulative_cnt_forum_activity >10  THEN '>10'
		END,
		'forum' AS category,
		SUM(has_verified) * 100.0/COUNT(1) AS p_verify,
		COUNT(1) AS cnt_users
	FROM 
		ahemphill.p_verify_model_master
	WHERE 
		week IN ('week_1')
	GROUP BY
		1
) a;

--agg number of users based on activity counts
SELECT
	cumulative_cnt_active_activity, 
	cumulative_cnt_engaged_activity,
	cumulative_cnt_video_activity, 
	cumulative_cnt_problem_activity, 
	cumulative_cnt_forum_activity,
	SUM(has_verified) AS cnt_verified,
	COUNT(1) AS cnt_users
FROM 
	ahemphill.p_verify_model_master
WHERE 
	week = 'week_1'
GROUP BY 
	cumulative_cnt_active_activity, 
	cumulative_cnt_engaged_activity,
	cumulative_cnt_video_activity, 
	cumulative_cnt_problem_activity, 
	cumulative_cnt_forum_activity;

--agg number of users based on days active/engaged
SELECT
	cumulative_is_active, 
	cumulative_is_engaged, 
	cumulative_is_engaged_video, 
	cumulative_is_engaged_problem, 
	cumulative_is_engaged_forum,
	SUM(has_verified) AS cnt_verified,
	COUNT(1) AS cnt_users
FROM 
	ahemphill.p_verify_model_master
WHERE 
	week IN ('week_1', 'week_2')
GROUP BY 
	cumulative_is_active, 
	cumulative_is_engaged, 
	cumulative_is_engaged_video, 
	cumulative_is_engaged_problem, 
	cumulative_is_engaged_forum


