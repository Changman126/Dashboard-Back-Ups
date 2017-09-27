drop table if exists ahemphill.user_first_course;
CREATE TABLE IF NOT EXISTS ahemphill.user_first_course AS


SELECT DISTINCT
    a.user_id,
    b.user_account_creation_time AS registration_date,
    a.first_course,
    c.catalog_course_title,
    a.first_enrollment_time AS first_course_enrollment_date,
    c.start_time AS first_course_start_date,
    DATEDIFF('day', b.user_account_creation_time, a.first_enrollment_time ) AS days_from_registration_to_first_enroll,
    e.first_verified_enrollment_time AS first_course_verified_enrollment_date,
    DATEDIFF('day', a.first_enrollment_time, e.first_verified_enrollment_time ) AS days_from_enroll_to_verification
FROM
(
    SELECT
        DISTINCT user_id,
        first_value(course_id) OVER (course_enrollment) AS first_course,
        MIN(first_enrollment_time) OVER (course_enrollment) AS first_enrollment_time
    FROM
        d_user_course
    WINDOW
            course_enrollment AS (PARTITION BY user_id ORDER BY first_enrollment_time ASc)
) a
JOIN
    d_user b
ON
    a.user_id = b.user_id
JOIN
    d_course c
ON
    a.first_course = c.course_id
JOIN
    d_user_course e
ON
    a.user_id = e.user_id
    AND a.first_course = e.course_id;

DROP TABLE IF EXISTS ahemphill.user_first_course_lifetime;
CREATE TABLE IF NOT EXISTS ahemphill.user_first_course_lifetime AS

SELECT 
    a.user_id,
    a.first_course,
    a.catalog_course_title,
    a.first_course_enrollment_date,
    a.first_course_start_date,
    a.days_from_registration_to_first_enroll,
    b.cnt_enrolls,
    b.cnt_verifs, 
    cnt_enrolls - 1 AS cnt_subsequent_enrolls,
    CASE WHEN cnt_enrolls > 1 THEN 1 ELSE 0 END AS has_subsequent_enrollment,
    CASE 
        WHEN first_course_verified_enrollment_date IS NULL THEN COALESCE(cnt_verifs, 0)
        WHEN first_course_verified_enrollment_date IS NOT NULL THEN COALESCE(cnt_verifs-1, 0)
        ELSE 0 
    END AS cnt_subsequent_verification,
    CASE 
        WHEN cnt_verifs > 0 AND first_course_verified_enrollment_date IS NULL THEN 1 
        WHEN cnt_verifs > 1 AND first_course_verified_enrollment_date IS NOT NULL THEN 1 
        ELSE 0 
    END AS has_subsequent_verification
FROM 
    ahemphill.user_first_course a 
JOIN 
(
    SELECT
        user_id,
        COUNT(1) AS cnt_enrolls,
        COUNT(first_verified_enrollment_time) AS cnt_verifs
    FROM 
        d_user_course
    GROUP BY
        user_id
) b
ON 
    a.user_id = b.user_id;

--can likely get this for free from an existing table in BI

DROP TABLE IF EXISTS ahemphill.course_vtr_enrolls;
CREATE TABLE IF NOT EXISTS ahemphill.course_vtr_enrolls AS

SELECT 
    a.course_id,
    COUNT(1) AS cnt_course_enrolls,
    COUNT(a.first_verified_enrollment_time) * 100.0/
    SUM(CASE WHEN a.first_enrollment_time <= b.course_seat_upgrade_deadline THEN 1 ELSE 0 END) AS vtr
FROM 
    d_user_course a
JOIN 
    d_course_seat b
on 
    a.course_id = b.course_id
AND 
    b.course_seat_type = 'verified'
GROUP BY 
    a.course_id
HAVING 
    SUM(CASE WHEN a.first_enrollment_time <= b.course_seat_upgrade_deadline THEN 1 ELSE 0 END) > 0;


DROP TABLE IF EXISTS ahemphill.user_first_course_summary;
CREATE TABLE IF NOT EXISTS ahemphill.user_first_course_summary AS

SELECT
    first_course_bucket,
    first_course,
    catalog_course_title,
    b.cnt_course_enrolls,
    b.vtr,
    cnt_users,
    sum_cnt_enrolls,
    sum_cnt_verifs,
    sum_cnt_subsequent_enrolls,
    sum_has_subsequent_enrollment,
    sum_cnt_subsequent_verification,
    sum_has_subsequent_verification,
    sum_has_subsequent_enrollment * 100.0 /cnt_users AS pct_users_future_enroll,
    sum_has_subsequent_verification * 100.0 /cnt_users AS pct_users_future_verify,
    sum_cnt_subsequent_enrolls /cnt_users AS enrolls_per_user,
    sum_cnt_subsequent_verification /cnt_users AS verifs_per_user,
    ROW_NUMBER() OVER (PARTITION BY first_course_bucket ORDER BY vtr DESC) AS rank_vtr,
    ROW_NUMBER() OVER (PARTITION BY first_course_bucket ORDER BY cnt_course_enrolls DESC) AS rank_cnt_course_enrolls,
    ROW_NUMBER() OVER (PARTITION BY first_course_bucket ORDER BY sum_has_subsequent_enrollment * 100.0 /cnt_users DESC) AS rank_pct_users_future_enroll,
    ROW_NUMBER() OVER (PARTITION BY first_course_bucket ORDER BY sum_has_subsequent_verification * 100.0 /cnt_users DESC) AS rank_pct_users_future_verify,
    ROW_NUMBER() OVER (PARTITION BY first_course_bucket ORDER BY sum_cnt_subsequent_enrolls /cnt_users DESC) AS rank_enrolls_per_user,
    ROW_NUMBER() OVER (PARTITION BY first_course_bucket ORDER BY sum_cnt_subsequent_verification /cnt_users DESC) AS rank_verifs_per_user
FROM
(
    SELECT 
        CASE 
            WHEN first_course_start_date between '2014-01-01' AND '2014-06-30' THEN '1H2014'
            WHEN first_course_start_date between '2014-07-01' AND '2014-12-31' THEN '2H2014'
            WHEN first_course_start_date between '2015-01-01' AND '2015-06-30' THEN '1H2015'
            WHEN first_course_start_date between '2015-07-01' AND '2015-12-31' THEN '2H2015'
            WHEN first_course_start_date between '2016-01-01' AND '2016-06-30' THEN '1H2016'
            WHEN first_course_start_date between '2016-07-01' AND '2016-12-31' THEN '2H2016'
        END AS first_course_bucket,
        first_course,
        catalog_course_title,
        COUNT(1) AS cnt_users,
        SUM(cnt_enrolls) AS sum_cnt_enrolls,
        SUM(cnt_verifs) AS sum_cnt_verifs,
        SUM(cnt_subsequent_enrolls) AS sum_cnt_subsequent_enrolls,
        SUM(has_subsequent_enrollment) AS sum_has_subsequent_enrollment,
        SUM(cnt_subsequent_verification) AS sum_cnt_subsequent_verification,
        SUM(has_subsequent_verification) AS sum_has_subsequent_verification
    FROM 
        ahemphill.user_first_course_lifetime
    WHERE 
        days_from_registration_to_first_enroll <=3
        AND first_course_start_date between '2014-01-01' AND '2016-12-31'
    GROUP BY 
        1,2,3
    HAVING 
        COUNT(1) > 500
) a
JOIN
   ahemphill.course_vtr_enrolls b
on 
    a.first_course = b.course_id;


