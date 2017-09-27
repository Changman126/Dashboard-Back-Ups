CREATE TABLE IF NOT EXISTS activity_engagement_user_daily (
        date DATE,
        user_id INTEGER,
        course_id VARCHAR(255),
        is_active INTEGER,
        cnt_active_activity INTEGER,
        is_engaged INTEGER,
        cnt_engaged_activity INTEGER,
        is_engaged_video INTEGER,
        cnt_video_activity INTEGER,
        is_engaged_problem INTEGER,
        cnt_problem_activity INTEGER,
        is_engaged_forum INTEGER,
        cnt_forum_activity INTEGER
);

--dummy insert to initialize the table

INSERT INTO activity_engagement_user_daily (date)
SELECT
    '2012-08-31' 
FROM 
    activity_engagement_user_daily
HAVING 
    COUNT(date)=0;

--daily record of what a user did in any given course on any given day

INSERT INTO activity_engagement_user_daily (

    SELECT
        date,
        user_id,
        course_id,
        SUM(CASE WHEN activity_type = 'ACTIVE' THEN 1 ELSE 0 END) AS is_active,
        SUM(CASE WHEN activity_type = 'ACTIVE' THEN number_of_activities ELSE 0 END) AS cnt_active_activity,
        CASE
            WHEN SUM(CASE WHEN activity_type IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM', 'POSTED_FORUM') THEN 1 ELSE 0 END) > 0 THEN 1 
        ELSE 0
        END AS is_engaged,
        SUM(CASE WHEN activity_type IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM', 'POSTED_FORUM') THEN number_of_activities ELSE 0 END) AS cnt_engaged_activity,
        SUM(CASE WHEN activity_type = 'PLAYED_VIDEO' THEN 1 ELSE 0 END) AS is_engaged_video,
        SUM(CASE WHEN activity_type = 'PLAYED_VIDEO' THEN number_of_activities ELSE 0 END) AS cnt_video_activity,
        SUM(CASE WHEN activity_type = 'ATTEMPTED_PROBLEM' THEN 1 ELSE 0 END) AS is_engaged_problem,
        SUM(CASE WHEN activity_type = 'ATTEMPTED_PROBLEM' THEN number_of_activities ELSE 0 END) AS cnt_problem_activity,
        SUM(CASE WHEN activity_type = 'POSTED_FORUM' THEN 1 ELSE 0 END) AS is_engaged_forum,
        SUM(CASE WHEN activity_type = 'POSTED_FORUM' THEN number_of_activities ELSE 0 END) AS cnt_forum_activity
    FROM 
        production.f_user_activity a
    JOIN 
    (
        SELECT
            MAX(date) AS latest_date
        FROM
            business_intelligence.activity_engagement_user_daily    
    ) b
    ON
        a.date > b.latest_date
    GROUP BY
        date,
        user_id,
        course_id
);

--rollup of user level view at the course level

DROP TABLE IF EXISTS activity_engagement_course_daily;
CREATE TABLE IF NOT EXISTS activity_engagement_course_daily AS

SELECT
    date,
    course_id,
    SUM(is_active) AS cnt_active_users,
    SUM(cnt_active_activity) AS sum_active_activity,
    SUM(is_engaged) AS cnt_engaged_users,
    SUM(cnt_engaged_activity) AS sum_engaged_activity,
    SUM(is_engaged_video) AS cnt_engaged_video_users,
    SUM(cnt_video_activity) AS sum_video_activity,
    SUM(is_engaged_problem) AS cnt_engaged_problem_users,
    SUM(cnt_problem_activity) AS sum_problem_activity,
    SUM(is_engaged_forum) AS cnt_engaged_forum_users,
    SUM(cnt_forum_activity) AS sum_forum_activity
FROM
    business_intelligence.activity_engagement_user_daily
GROUP BY
    date,
    course_id;

--find all new users who are eligible for inclusion in activity/engagement calculations

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
LEFT JOIN
    production.d_user_course_certificate cert
ON
    user_course.user_id = cert.user_id
AND
    user_course.course_id = cert.course_id
JOIN
(
    SELECT 
        MAX(date) AS date 
    FROM 
        business_intelligence.user_activity_engagement_summary
    WHERE
        date != '2012-08-31'
) latest
ON
    CASE 
        WHEN DATE(user_course.first_enrollment_time) >= course.course_start_date THEN DATE(user_course.first_enrollment_time)
        ELSE course.course_start_date
    END BETWEEN latest.date AND CURRENT_DATE();

--add the 60d of date records for the new users
--look for activity for any new dates

INSERT INTO ahemphill.user_activity_engagement (

SELECT 
    cal.date,
    users.user_id,
    users.course_id,
    DATEDIFF('day', users.content_availability_date, cal.date) AS days_from_content_availability,
    CASE
        WHEN users.days_from_content_availability BETWEEN 0 AND 6 THEN 'week_1'
        WHEN users.days_from_content_availability BETWEEN 7 AND 13 THEN 'week_2'
        WHEN users.days_from_content_availability BETWEEN 14 AND 20 THEN 'week_3'
        WHEN users.days_from_content_availability BETWEEN 21 AND 27 THEN 'week_4'
        WHEN users.days_from_content_availability BETWEEN 28 AND 34 THEN 'week_5'
        WHEN users.days_from_content_availability BETWEEN 35 AND 41 THEN 'week_6'
        WHEN users.days_from_content_availability BETWEEN 42 AND 48 THEN 'week_7'
        WHEN users.days_from_content_availability BETWEEN 49 AND 55 THEN 'week_8'
        ELSE 'week_9'
    END AS week,
    COALESCE(activity.is_active, 0) AS is_active,
    COALESCE(activity.cnt_active_activity, 0) AS cnt_active_activity,
    COALESCE(activity.is_engaged, 0) AS is_engaged,
    COALESCE(activity.cnt_engaged_activity, 0) AS cnt_engaged_activity,
    COALESCE(activity.is_engaged_video, 0) AS is_engaged_video,
    COALESCE(activity.cnt_video_activity, 0) AS cnt_video_activity,
    COALESCE(activity.is_engaged_problem, 0) AS is_engaged_problem,
    COALESCE(activity.cnt_problem_activity, 0) AS cnt_problem_activity,
    COALESCE(activity.is_engaged_forum, 0) AS is_engaged_forum,
    COALESCE(activity.cnt_forum_activity, 0) AS cnt_forum_activity,
FROM 
    tmp_activity_engagement_eligible_users users
JOIN
    business_intelligence.calendar cal
ON 
    DATEDIFF('day', users.content_availability_date, cal.date) BETWEEN 0 AND 30
JOIN
    (
        SELECT
            MAX(date) AS latest_date
        FROM
            user_activity_engagement_summary
    ) latest
ON
    1=1
LEFT JOIN
    business_intelligence.activity_engagement_user_daily activity
ON 
    users.user_id = activity.user_id
AND 
    users.course_id = activity.course_id
AND
    activity.date > latest.date
AND 
    cal.date = activity.date
);

DROP TABLE IF EXISTS ahemphill.user_activity_engagement_summary;
CREATE TABLE ahemphill.user_activity_engagement_summary AS 
SELECT
    date,
    a.user_id,
    a.course_id,
    a.week,
    SUM(is_engaged) AS days_engaged,
    SUM(is_active) AS days_active,
    CASE 
        WHEN SUM(is_engaged) = 0 THEN 'no_engagement' 
        WHEN SUM(is_engaged) = 1 THEN 'minimal_engagement'
        ELSE 'high_engagement' 
    END AS weekly_engagement_level
FROM 
    ahemphill.user_activity_engagement a
GROUP BY 
    date,
    a.user_id,
    a.course_id,
    a.week;
