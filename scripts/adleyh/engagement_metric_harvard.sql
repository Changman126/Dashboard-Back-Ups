--initialize the eligible users table
DROP TABLE IF EXISTS ahemphill.user_activity_engagement_eligible_users;
CREATE TABLE IF NOT EXISTS ahemphill.user_activity_engagement_eligible_users (
        date DATE,
        user_id INTEGER,
        course_id VARCHAR(255),
        content_availability_date DATE,
        first_enrollment_date DATE,
        last_unenrollment_date DATE,
        course_pass_date DATE,
        days_from_content_availability INTEGER,
        week VARCHAR(255)
);



--dummy insert to initialize the table

INSERT INTO ahemphill.user_activity_engagement_eligible_users (date)
SELECT
    '2016-05-09' 
FROM 
    ahemphill.user_activity_engagement_eligible_users
HAVING 
    COUNT(date)=0;


--identify the new users that we want to start tracking for engagement

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
        MAX(date) AS date 
    FROM 
       ahemphill.user_activity_engagement_eligible_users
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

INSERT INTO ahemphill.user_activity_engagement_eligible_users (

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
            user_id,
            course_id,
            content_availability_date,
            first_enrollment_date,
            last_unenrollment_date,
            course_pass_date,
            content_availability_date AS latest_date
        FROM
            tmp_activity_engagement_eligible_users

        UNION ALL

        SELECT
            user_id,
            course_id,
            content_availability_date,
            first_enrollment_date,
            last_unenrollment_date,
            course_pass_date,
            MAX(date) + 1 AS latest_date
        FROM
            ahemphill.user_activity_engagement_eligible_users
        GROUP BY
            user_id,
            course_id,
            content_availability_date,
            first_enrollment_date,
            last_unenrollment_date,
            course_pass_date
    ) users
    JOIN
        business_intelligence.calendar cal
    ON
        cal.date BETWEEN users.latest_date AND CURRENT_DATE()
    AND
        DATEDIFF('day', users.latest_date, cal.date) BETWEEN 0 AND 14
);

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
AND
	course.course_partner = 'HarvardX'
AND
    CASE 
        WHEN DATE(user_course.first_enrollment_time) >= course.course_start_date THEN DATE(user_course.first_enrollment_time)
        ELSE course.course_start_date
    END BETWEEN '2016-05-09' AND CURRENT_DATE()
LEFT JOIN
    production.d_user_course_certificate cert
ON
    user_course.user_id = cert.user_id
AND
    user_course.course_id = cert.course_id;


DROP TABLE IF EXISTS ahemphill.user_activity_engagement_eligible_users_engagement_date;
CREATE TABLE IF NOT EXISTS ahemphill.user_activity_engagement_eligible_users_engagement_date AS

SELECT 
    users.user_id,
    users.course_id,
    users.content_availability_date,
    users.first_enrollment_date,
    users.last_unenrollment_date,
    users.course_pass_date,
    DATEDIFF('day', users.content_availability_date, engagement.first_engagement_date) AS days_content_availability_first_engagement
FROM 
	tmp_activity_engagement_eligible_users users
JOIN
(
	SELECT
		user_id,
		course_id,
		MIN(date) AS first_engagement_date
	FROM
		production.f_user_activity
	WHERE
		activity_type != 'ACTIVE'
	GROUP BY
		user_id,
		course_id
) engagement
ON
	users.user_id = engagement.user_id
AND
	users.course_id = engagement.course_id;

--map each (day, user_id, course_id) to their activity for that day
--remove users from calculation as soon as they unenroll or complete
--choosing to do this over the entire table everyday in case we add new engagement actions that we would like to backfill

DROP TABLE IF EXISTS ahemphill.user_activity_engagement_daily;
CREATE TABLE IF NOT EXISTS ahemphill.user_activity_engagement_daily AS

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
    COALESCE(activity.is_engaged, 0) AS is_engaged
FROM 
    ahemphill.user_activity_engagement_eligible_users users
LEFT JOIN
    ahemphill.activity_engagement_user_daily activity
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


--weekly rollup per (user_id, course_id)
SELECT
	CASE
		WHEN engagement_7d = 0 THEN 'no_engagement'
		WHEN engagement_7d = 1 THEN 'minimal_engagement'
	ELSE
		'high_engagement'
	END AS engagement_level_7d,
	CASE
		WHEN engagement_10d = 0 THEN 'no_engagement'
		WHEN engagement_10d = 1 THEN 'minimal_engagement'
	ELSE
		'high_engagement'
	END AS engagement_level_10d,
	CASE
		WHEN engagement_12d = 0 THEN 'no_engagement'
		WHEN engagement_12d = 1 THEN 'minimal_engagement'
	ELSE
		'high_engagement'
	END AS engagement_level_12d,
	CASE
		WHEN engagement_14d = 0 THEN 'no_engagement'
		WHEN engagement_14d = 1 THEN 'minimal_engagement'
	ELSE
		'high_engagement'
	END AS engagement_level_14d,
	course_id,
	COUNT(user_id) AS cnt_users
FROM
(
	SELECT
		user_id,
		course_id,
		SUM(CASE WHEN days_from_content_availability < 6 THEN is_engaged ELSE 0 END) AS engagement_7d,
		SUM(CASE WHEN days_from_content_availability < 9 THEN is_engaged ELSE 0 END) AS engagement_10d,
		SUM(CASE WHEN days_from_content_availability < 11 THEN is_engaged ELSE 0 END) AS engagement_12d,
		SUM(CASE WHEN days_from_content_availability < 13 THEN is_engaged ELSE 0 END) AS engagement_14d
	FROM
		ahemphill.user_activity_engagement_daily
	GROUP BY
		user_id,
		course_id
) a
GROUP BY 
	1,2,3,4,5


DROP TABLE IF EXISTS ahemphill.user_activity_engagement_weekly;
CREATE TABLE ahemphill.user_activity_engagement_weekly AS 
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
    ahemphill.user_activity_engagement_daily
GROUP BY 
    user_id,
    course_id,
    week;

--aggregated daily rollup

DROP TABLE IF EXISTS ahemphill.user_activity_engagement_daily_agg;
CREATE TABLE ahemphill.user_activity_engagement_daily_agg AS 
SELECT
    daily.date,
    daily.course_id,
    daily.week,
    daily.weekly_engagement_level,
    week1.weekly_engagement_level AS week_1_engagement_level,
    COUNT(1) AS cnt_users
FROM 
    ahemphill.user_activity_engagement_daily daily
JOIN
    ahemphill.user_activity_engagement_weekly week1
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

DROP TABLE IF EXISTS ahemphill.user_activity_engagement_weekly_agg;
CREATE TABLE ahemphill.user_activity_engagement_weekly_agg AS 
SELECT
    summary.course_id,
    summary.week,
    summary.weekly_engagement_level,
    week1.weekly_engagement_level AS week_1_engagement_level,
    COUNT(1) AS cnt_users
FROM 
    ahemphill.user_activity_engagement_weekly summary
JOIN
    (
        SELECT
            user_id,
            course_id,
            weekly_engagement_level
        FROM
            ahemphill.user_activity_engagement_weekly
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