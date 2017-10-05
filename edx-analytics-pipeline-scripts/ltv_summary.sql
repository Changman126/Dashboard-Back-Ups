--find the first course a user enrolls in

DROP TABLE IF EXISTS tmp_user_first_course;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_user_first_course ON COMMIT PRESERVE ROWS AS

SELECT
    course.user_id,
    YEAR(DATE(first_enrollment_time)) - u.user_year_of_birth AS user_age,
    u.user_level_of_education,
    u.user_gender,
    u.user_last_location_country_code,
    course.course_id AS first_course_id,
    DATE(first_enrollment_time) AS first_course_enrollment_date,
    DATE(first_verified_enrollment_time) AS first_course_verified_enrollment_date
FROM
(
    SELECT
        user_id,
        course_id,
        first_enrollment_time,
        first_verified_enrollment_time,
        ROW_NUMBER() OVER (partition by user_id ORDER BY first_enrollment_time ASC) AS rank
    FROM
        production.d_user_course
) course
JOIN
    production.d_user u
ON
    course.user_id = u.user_id
WHERE
    course.rank = 1;

--collect lifetime stats about that user after their first enrollment

DROP TABLE IF EXISTS tmp_user_first_course_lifetime;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_user_first_course_lifetime ON COMMIT PRESERVE ROWS AS

SELECT 
    first_course.user_id,
    first_course.user_age,
    first_course.user_level_of_education,
    first_course.user_gender,
    first_course.user_last_location_country_code,
    first_course.first_course_id,
    first_course.first_course_enrollment_date,
    first_course.first_course_verified_enrollment_date,
    all_courses.cnt_enrolls,
    all_courses.cnt_verifs, 
    (all_courses.cnt_enrolls - 1) AS cnt_subsequent_enrolls,
    CASE 
        WHEN all_courses.cnt_enrolls > 1 
        THEN 1 
        ELSE 0 
    END AS has_subsequent_enrollment,
    CASE 
        WHEN first_course.first_course_verified_enrollment_date IS NULL THEN COALESCE(all_courses.cnt_verifs, 0)
        WHEN first_course.first_course_verified_enrollment_date IS NOT NULL THEN COALESCE(all_courses.cnt_verifs-1, 0)
        ELSE 0 
    END AS cnt_subsequent_verification,
    CASE 
        WHEN all_courses.cnt_verifs > 0 AND first_course.first_course_verified_enrollment_date IS NULL THEN 1 
        WHEN all_courses.cnt_verifs > 1 AND first_course.first_course_verified_enrollment_date IS NOT NULL THEN 1 
        ELSE 0 
    END AS has_subsequent_verification
FROM 
    tmp_user_first_course first_course
JOIN 
(
    SELECT
        user_id,
        COUNT(1) AS cnt_enrolls,
        COUNT(first_verified_enrollment_time) AS cnt_verifs
    FROM 
        production.d_user_course
    GROUP BY
        user_id
) all_courses
ON 
    first_course.user_id = all_courses.user_id;

--aggregate lifetime stats about the user to feed further calculations in Tableau towards lifetime value (LTV)

DROP TABLE IF EXISTS ltv_summary;
CREATE TABLE IF NOT EXISTS ltv_summary AS

SELECT
    first_course.first_course_enrollment_date,
    first_course.first_course_id,
    first_course.user_age,
    first_course.user_level_of_education,
    CASE
        WHEN first_course.user_gender IN ('m', 'f') THEN first_course.user_gender
        ELSE 'undefined'
    END AS user_gender,
    first_course.user_last_location_country_code,
    summary.vtr,
    first_course.cnt_users,
    first_course.sum_enrolls,
    first_course.sum_verifs,
    first_course.sum_subsequent_enrolls,
    first_course.cnt_users_subsequent_enrollment,
    first_course.sum_subsequent_verifications,
    first_course.cnt_users_subsequent_verification
FROM
(
    SELECT 
        first_course_enrollment_date,
        first_course_id,
        user_age,
        user_level_of_education,
        user_gender,
        user_last_location_country_code,
        COUNT(1) AS cnt_users,
        SUM(cnt_enrolls) AS sum_enrolls,
        SUM(cnt_verifs) AS sum_verifs,
        SUM(cnt_subsequent_enrolls) AS sum_subsequent_enrolls,
        SUM(has_subsequent_enrollment) AS cnt_users_subsequent_enrollment,
        SUM(cnt_subsequent_verification) AS sum_subsequent_verifications,
        SUM(has_subsequent_verification) AS cnt_users_subsequent_verification
    FROM 
        tmp_user_first_course_lifetime
    GROUP BY 
        first_course_enrollment_date,
        first_course_id,
        user_age,
        user_level_of_education,
        user_gender,
        user_last_location_country_code
) first_course
JOIN
    business_intelligence.course_stats_summary summary
ON 
    first_course.first_course_id = summary.course_id;

DROP TABLE tmp_user_first_course;
DROP TABLE tmp_user_first_course_lifetime;

GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO standard;
GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO analyst;