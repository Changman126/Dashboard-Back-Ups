
DROP TABLE IF EXISTS tmp_activity_engagement_eligible_users;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_activity_engagement_eligible_users ON COMMIT PRESERVE ROWS AS

SELECT
    user_course.user_id,
    user_course.course_id,
    CASE 
        WHEN DATE(user_course.first_enrollment_time) >= course.course_start_date THEN DATE(user_course.first_enrollment_time)
        ELSE course.course_start_date
    END AS content_availability_date,
    DATE(user_course.first_enrollment_time) AS first_enrollment_date,
    DATE(user_course.last_unenrollment_time) AS last_unenrollment_date,
    CASE
        WHEN cert.has_passed = 1 THEN DATE(cert.modified_date)
        ELSE NULL
    END AS course_pass_date,
    course.course_start_date
FROM 
    production.d_user_course user_course
JOIN 
    business_intelligence.course_master course
ON 
    user_course.course_id = course.course_id
JOIN
(
    SELECT 
        MIN(date) AS date 
    FROM 
       business_intelligence.user_activity_engagement_stg
    WHERE
        date != '2012-08-31'
) latest
ON
    CASE 
        WHEN DATE(user_course.first_enrollment_time) >= course.course_start_date THEN DATE(user_course.first_enrollment_time)
        ELSE course.course_start_date
    END BETWEEN latest.date + 1 AND CURRENT_DATE()
LEFT JOIN
    production.d_user_course_certificate cert
ON
    user_course.user_id = cert.user_id
AND
    user_course.course_id = cert.course_id;

--add the new users from above into the master tracking table
--add new dates for all users who are within 35 days of content availability

INSERT INTO business_intelligence.activity_engagement_eligible_users (

    SELECT 
        cal.date,
        users.user_id,
        users.course_id,
        users.content_availability_date,
        users.first_enrollment_date,
        users.last_unenrollment_date,
        users.course_pass_date,
        DATEDIFF('day', users.content_availability_date, cal.date) AS days_from_content_availability,
        CASE
            WHEN DATEDIFF('day', users.content_availability_date, cal.date) BETWEEN 0 AND 6 THEN 'week_1'
            WHEN DATEDIFF('day', users.content_availability_date, cal.date) BETWEEN 7 AND 13 THEN 'week_2'
            WHEN DATEDIFF('day', users.content_availability_date, cal.date) BETWEEN 14 AND 20 THEN 'week_3'
            WHEN DATEDIFF('day', users.content_availability_date, cal.date) BETWEEN 21 AND 27 THEN 'week_4'
            WHEN DATEDIFF('day', users.content_availability_date, cal.date) BETWEEN 28 AND 34 THEN 'week_5'
            ELSE 'week_5'
        END AS week
    FROM
    (
        SELECT
            users.user_id,
            users.course_id,
            users.content_availability_date,
            users.first_enrollment_date,
            users.last_unenrollment_date,
            users.course_pass_date,
            users.content_availability_date AS latest_date
        FROM
            tmp_activity_engagement_eligible_users users

        UNION ALL

        SELECT
            users.user_id,
            users.course_id,
            users.content_availability_date,
            users.first_enrollment_date,
            users.last_unenrollment_date,
            users.course_pass_date,
            MAX(users.date) AS latest_date
        FROM
            business_intelligence.activity_engagement_eligible_users users
        GROUP BY
            users.user_id,
            users.course_id,
            users.content_availability_date,
            users.first_enrollment_date,
            users.last_unenrollment_date,
            users.course_pass_date
    ) users
    JOIN
        business_intelligence.calendar cal
    ON
        calendar.date BETWEEN users.latest_date + 1 AND CURRENT_DATE()
    AND
        DATEDIFF('day', users.latest_date, cal.date) BETWEEN 0 AND 34
);

--map each (day, user_id, course_id) to their activity for that day
--remove users from calculation as soon as they unenroll or complete
--choosing to do this over the entire table everyday in case we add new engagement actions that we would like to backfill

DROP TABLE IF EXISTS tmp_user_activity_engagement_daily;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_user_activity_engagement_daily ON COMMIT PRESERVE ROWS AS

SELECT 
    users.date,
    users.user_id,
    users.course_id,
    users.content_availability_date,
    users.first_enrollment_date,
    users.last_unenrollment_date,
    users.course_pass_date,
    users.days_from_content_availability,
    users.week,
    COALESCE(activity.is_active, 0) AS is_active,
    COALESCE(activity.cnt_active_activity, 0) AS cnt_active_activity,
    COALESCE(activity.is_engaged, 0) AS is_engaged,
    COALESCE(activity.cnt_engaged_activity, 0) AS cnt_engaged_activity,
    COALESCE(activity.is_engaged_video, 0) AS is_engaged_video,
    COALESCE(activity.cnt_video_activity, 0) AS cnt_video_activity,
    COALESCE(activity.is_engaged_problem, 0) AS is_engaged_problem,
    COALESCE(activity.cnt_problem_activity, 0) AS cnt_problem_activity,
    COALESCE(activity.is_engaged_forum, 0) AS is_engaged_forum,
    COALESCE(activity.cnt_forum_activity, 0) AS cnt_forum_activity
FROM 
    business_intelligence.activity_engagement_eligible_users users
LEFT JOIN
    business_intelligence.activity_engagement_user_daily activity
ON 
    users.user_id = activity.user_id
AND 
    users.course_id = activity.course_id
AND 
    users.date = activity.date
WHERE
(
    users.date <= users.last_unenrollment_date
    OR
    users.last_unenrollment_date IS NULL
)
AND
(
    users.date <= users.course_pass_date
    OR
    users.course_pass_date IS NULL
);

--daily rollup per (user_id, course_id)

DROP TABLE IF EXISTS business_intelligence.user_activity_engagement_daily;
CREATE TABLE IF NOT EXISTS business_intelligence.user_activity_engagement_daily AS

SELECT
    date,
    user_id,
    course_id,
    week,
    SUM(is_engaged) AS days_engaged,
    SUM(is_active) AS days_active,
    CASE 
        WHEN SUM(is_engaged) OVER (PARTITION BY user_id, course_id, week ORDER BY date) = 0 THEN 'no_engagement' 
        WHEN SUM(is_engaged) OVER (PARTITION BY user_id, course_id, week ORDER BY date) = 1 THEN 'minimal_engagement'
        ELSE 'high_engagement' 
    END AS weekly_engagement_level
FROM 
    tmp_user_activity_engagement_daily
GROUP BY 
    date,
    user_id,
    course_id,
    week;

--weekly rollup per (user_id, course_id)

DROP TABLE IF EXISTS business_intelligence.user_activity_engagement_weekly;
CREATE TABLE business_intelligence.user_activity_engagement_weekly AS 
SELECT
    user_id,
    course_id,
    week,
    SUM(is_engaged) AS days_engaged,
    SUM(is_active) AS days_active,
    CASE 
        WHEN SUM(is_engaged) = 0 THEN 'no_engagement' 
        WHEN SUM(is_engaged) = 1 THEN 'minimal_engagement'
        ELSE 'high_engagement' 
    END AS weekly_engagement_level
FROM 
    business_intelligence.user_activity_engagement_daily
GROUP BY 
    user_id,
    course_id,
    week;

--aggregated daily rollup

DROP TABLE IF EXISTS business_intelligence.user_activity_engagement_daily_agg;
CREATE TABLE business_intelligence.user_activity_engagement_daily_agg AS 
SELECT
    daily.date,
    daily.course_id,
    daily.week,
    daily.weekly_engagement_level,
    week1.weekly_engagement_level AS week_1_engagement_level,
    COUNT(1) AS cnt_users
FROM 
    business_intelligence.user_activity_engagement_daily daily
JOIN
    business_intelligence.user_activity_engagement_weekly week1
ON
    daily.user_id = week1.user_id
AND
    daily.course_id = week1.course_id
AND
    week1.week = 'week_1'
GROUP BY 
    daily.date,
    daily.course_id,
    daily.week,
    daily.weekly_engagement_level,
    week1.weekly_engagement_level;


--aggregated weekly rollup

DROP TABLE IF EXISTS business_intelligence.user_activity_engagement_weekly_agg;
CREATE TABLE business_intelligence.user_activity_engagement_weekly_agg AS 
SELECT
    summary.course_id,
    summary.week,
    summary.weekly_engagement_level,
    week1.weekly_engagement_level AS week_1_engagement_level,
    COUNT(1) AS cnt_users
FROM 
    business_intelligence.user_activity_engagement_weekly summary
JOIN
    (
        SELECT
            user_id,
            course_id,
            weekly_engagement_level
        FROM
            business_intelligence.user_activity_engagement_weekly
        WHERE
            week = 'week_1'
    ) week1
ON
    summary.user_id = week1.user_id
AND
    summary.course_id = week1.course_id
GROUP BY 
    summary.course_id,
    summary.week,
    summary.weekly_engagement_level,
    week1.weekly_engagement_level;

DROP TABLE tmp_activity_engagement_eligible_users;
DROP TABLE tmp_user_activity_engagement_daily;
