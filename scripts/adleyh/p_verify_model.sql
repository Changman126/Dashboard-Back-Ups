SELECT
    a.user_id,
    CASE WHEN current_enrollment_mode = 'verified' THEN 1 ELSE 0 END AS is_verified,
    COALESCE(cnt_2016_enrolls, 0) AS cnt_2016_enrolls,
    COALESCE(cnt_2015_enrolls, 0) AS cnt_2015_enrolls,
    COALESCE(cnt_prior_enrolls, 0) AS cnt_prior_enrolls,
    COALESCE(cnt_2016_verifs, 0) AS cnt_2016_verifs,
    COALESCE(cnt_2015_verifs, 0) AS cnt_2015_verifs,
    COALESCE(cnt_prior_verifs, 0) AS cnt_prior_verifs,
    COALESCE(cnt_passed, 0) AS cnt_passed,
    COALESCE(cnt_certs, 0) AS cnt_certs,
    COALESCE(cnt_days_active, 0) AS cnt_days_active,
    COALESCE(cnt_active_activity, 0) AS cnt_active_activity,
    COALESCE(cnt_days_engaged, 0) AS cnt_days_engaged,
    COALESCE(cnt_engaged_activity, 0) AS cnt_engaged_activity,
    COALESCE(cnt_days_engaged_video, 0) AS cnt_days_engaged_video,
    COALESCE(cnt_video_activity, 0) AS cnt_video_activity,
    COALESCE(cnt_days_engaged_problem, 0) AS cnt_days_engaged_problem,
    COALESCE(cnt_problem_activity, 0) AS cnt_problem_activity,
    COALESCE(cnt_days_engaged_forum, 0) AS cnt_days_engaged_forum,
    COALESCE(cnt_forum_activity, 0) AS cnt_forum_activity,
    COALESCE(CAST(max_grade AS INT), 0) AS max_grade,
    d_user.user_year_of_birth,
    d_user.user_level_of_education,
    d_user.user_gender,
    d_user.user_last_location_country_code
FROM 
    production.d_user_course a
LEFT JOIN
(
    SELECT 
        user_id,
        COUNT(1) AS cnt_prior_enrolls,
        SUM(CASE WHEN year(first_enrollment_time) = '2016' THEN 1 ELSE 0 END) as cnt_2016_enrolls,
        SUM(CASE WHEN year(first_enrollment_time) = '2015' THEN 1 ELSE 0 END) as cnt_2015_enrolls,
        COUNT(first_verified_enrollment_time) AS cnt_prior_verifs,
        SUM(CASE WHEN year(first_verified_enrollment_time) = '2016' THEN 1 ELSE 0 END) as cnt_2016_verifs,
        SUM(CASE WHEN year(first_verified_enrollment_time) = '2015' THEN 1 ELSE 0 END) as cnt_2015_verifs
    FROM 
        production.d_user_course
    WHERE 
        first_enrollment_time < '2017-01-01'
    GROUP BY
        user_id
) prior_verifs_enrolls
ON 
    a.user_id = prior_verifs_enrolls.user_id
JOIN 
    production.d_user d_user
ON 
    a.user_id = d_user.user_id
LEFT JOIN
(
    SELECT
        user_id,
        SUM(has_passed) AS cnt_passed,
        SUM(is_certified) AS cnt_certs,
        --AVG(final_grade) AS avg_grade,
        MAX(final_grade) AS max_grade
    FROM
        production.d_user_course_certificate
    WHERE
        DATE(modified_date) < '2017-01-01'
    GROUP BY 
        user_id
) prior_certs_passes
ON 
    a.user_id = prior_certs_passes.user_id
LEFT JOIN
(
    SELECT
        user_id,
        SUM(is_active) AS cnt_days_active,
        SUM(cnt_active_activity) AS cnt_active_activity,
        SUM(is_engaged) AS cnt_days_engaged,
        SUM(cnt_engaged_activity) AS cnt_engaged_activity,
        SUM(is_engaged_video) AS cnt_days_engaged_video,
        SUM(cnt_video_activity) AS cnt_video_activity,
        SUM(is_engaged_problem) AS cnt_days_engaged_problem,
        SUM(cnt_problem_activity) AS cnt_problem_activity,
        SUM(is_engaged_forum) AS cnt_days_engaged_forum,
        SUM(cnt_forum_activity) AS cnt_forum_activity
    FROM
        business_intelligence.activity_engagement_user_daily
    WHERE
        date < '2017-01-01'
    GROUP BY 
        user_id
) prior_activity_engagement
ON 
    a.user_id = prior_activity_engagement.user_id
WHERE 
    a.first_enrollment_time >= '2017-01-01'