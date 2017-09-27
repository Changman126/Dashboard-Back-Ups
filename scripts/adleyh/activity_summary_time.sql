CREATE TABLE IF NOT EXISTS activity_engagement_daily (
        date DATE,
        course_id VARCHAR(255),
        cnt_is_active INTEGER,
        sum_active_activity_count INTEGER
        cnt_is_engaged INTEGER,
        sum_engaged_activity_count INTEGER,
        cnt_is_engaged_video INTEGER,
        sum_video_activity_count INTEGER,
        cnt_is_engaged_problem INTEGER,
        sum_problem_activity_count INTEGER,
        cnt_is_engaged_forum INTEGER,
        sum_forum_activity_count INTEGER
);

INSERT INTO activity_engagement_daily (
    SELECT
        date,
        course_id,
        SUM(is_active) AS cnt_is_active,
        SUM(active_activity_count) AS sum_active_activity_count,
        SUM(is_engaged) AS cnt_is_engaged,
        SUM(engaged_activity_count) AS sum_engaged_activity_count,
        SUM(is_engaged_video) AS cnt_is_engaged_video,
        SUM(video_activity_count) AS sum_video_activity_count,
        SUM(is_engaged_problem) AS cnt_is_engaged_problem,
        SUM(problem_activity_count) AS sum_problem_activity_count,
        SUM(is_engaged_forum) AS cnt_is_engaged_forum,
        SUM(forum_activity_count) AS sum_forum_activity_count
    FROM
    (
        SELECT
            date,
            course_id,
            user_id,
            SUM(CASE WHEN activity_type = 'ACTIVE' THEN 1 ELSE 0 END) AS is_active,
            SUM(CASE WHEN activity_type = 'ACTIVE' THEN number_of_activities ELSE 0 END) AS active_activity_count,
            SUM(CASE WHEN activity_type IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM', 'POSTED_FORUM') THEN 1 ELSE 0 END) AS is_engaged,
            SUM(CASE WHEN activity_type IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM', 'POSTED_FORUM') THEN number_of_activities ELSE 0 END) AS engaged_activity_count,
            SUM(CASE WHEN activity_type = 'PLAYED_VIDEO' THEN 1 ELSE 0 END) AS is_engaged_video,
            SUM(CASE WHEN activity_type = 'PLAYED_VIDEO' THEN number_of_activities ELSE 0 END) AS video_activity_count,
            SUM(CASE WHEN activity_type = 'ATTEMPTED_PROBLEM' THEN 1 ELSE 0 END) AS is_engaged_problem,
            SUM(CASE WHEN activity_type = 'ATTEMPTED_PROBLEM' THEN number_of_activities ELSE 0 END) AS problem_activity_count,
            SUM(CASE WHEN activity_type = 'POSTED_FORUM' THEN 1 ELSE 0 END) AS is_engaged_forum,
            SUM(CASE WHEN activity_type = 'POSTED_FORUM' THEN number_of_activities ELSE 0 END) AS forum_activity_count
        FROM 
            production.f_user_activity a
        JOIN 
        (
            SELECT
                MAX(date) AS latest_date
            FROM
                activity_engagement_daily    
        ) b
        ON
            1=1
        AND 
            a.date > b.latest_date
        GROUP BY
            date,
            course_id,
            user_id
    ) a
    GROUP BY
        date,
        course_id
);
