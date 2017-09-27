

DROP TABLE IF EXISTS ahemphill.bundling_experiment_transactions;
CREATE TABLE IF NOT EXISTS ahemphill.bundling_experiment_transactions AS

SELECT
    viewed.variation_name,
    viewed.user_id,
    -- Count them as "converted" if they have made any purchases after being exposed to the treatment
    -- regardless of course_id etc.
    CASE WHEN SUM(purchased.cnt_sales) > 0 THEN 1 ELSE 0 END AS converted,
    
    -- For now, ignore refunds, just look at total bookings.
    SUM(purchased.gross_bookings) AS bookings
FROM

-- This subquery gathers all users who have been exposed to exactly one variant for this experiment
(
    SELECT
        user_id,
        course_id,
        MIN(variation_name) AS variation_name,
        MIN(received_at) AS exposure_time
    FROM
        business_intelligence.experiment_exposure
    WHERE
        experiment_name = 'Program Purchase Test with Discount Run 2'
    GROUP BY 1, 2
    HAVING COUNT(DISTINCT variation_name) = 1
) AS viewed

-- Need to join with d_user to get their username
JOIN 
    production.d_user du 
ON 
    du.user_id = viewed.user_id

-- Now join with our finance table to find all sales and refunds for this user that are *after* the first exposure
LEFT JOIN
(
    SELECT
        f.order_username AS username,
        f.order_course_id AS course_id,
        MIN(f.order_timestamp)::TIMESTAMPTZ AS purchase_time,
        SUM(f.transaction_amount_per_item) AS net_bookings,
        SUM(CASE WHEN f.transaction_type = 'sale' THEN f.transaction_amount_per_item ELSE 0 END) AS gross_bookings,
        SUM(CASE WHEN f.transaction_type = 'refund' THEN f.transaction_amount_per_item ELSE 0 END) AS gross_refunds,
        SUM(CASE WHEN f.transaction_type = 'sale' THEN 1 ELSE 0 END) AS cnt_sales,
        SUM(CASE WHEN f.transaction_type = 'refund' THEN 1 ELSE 0 END) AS cnt_refunds
    FROM
        finance.f_orderitem_transactions f
    JOIN
        production.d_program_course p
    ON 
        f.order_course_id = p.course_id
    AND 
        p.program_id IN (
    '10339d1d-239d-4e36-b524-8ce0fdf2d0c0',
    'a78e76d2-7e0b-4865-8013-0e037ebdc0f9',
    '482dee71-e4b9-4b42-a47b-3e16bb69e8f2',
    'a015ce08-a727-46c8-92d1-679b23338bc1',
    '98b7344e-cd44-4a99-9542-09dfdb11d31b'
        )
    AND
        f.transaction_type IS NOT NULL
    AND 
        f.order_username IS NOT NULL
    AND 
        f.partner_short_code = 'edx'
    GROUP BY
        1, 
        2
) AS purchased
ON  
    du.user_username = purchased.username
AND 
    purchased.purchase_time >= viewed.exposure_time
GROUP BY 
    1, 
    2;

DROP TABLE IF EXISTS ahemphill.bundling_experiment_enrolls_engagement;
CREATE TABLE IF NOT EXISTS ahemphill.bundling_experiment_enrolls_engagement AS

SELECT
    viewed.variation_name,
    viewed.user_id,
    enrolled.course_id AS enrolled_course,
    CASE WHEN enrolled.first_verified_enrollment_time >= viewed.exposure_time THEN 1 ELSE 0 END AS has_verified,
    enrolled.program_slot_number,
    COALESCE(engagement.weekly_engagement_level, 'course_not_started') AS weekly_engagement_level

FROM

-- This subquery gathers all users who have been exposed to exactly one variant for this experiment
(
    SELECT
        user_id,
        course_id,
        MIN(variation_name) AS variation_name,
        MIN(received_at) AS exposure_time
    FROM
        business_intelligence.experiment_exposure
    WHERE
        experiment_name = 'Program Purchase Test with Discount Run 2'
    GROUP BY 1, 2
    HAVING COUNT(DISTINCT variation_name) = 1
) AS viewed
LEFT JOIN
(
    SELECT
        user_course.user_id,
        user_course.course_id,
        user_course.first_enrollment_time,
        user_course.first_verified_enrollment_time,
        p.program_slot_number
    FROM
        production.d_user_course user_course
    JOIN
        production.d_program_course p
    ON 
        user_course.course_id = p.course_id
    AND 
        p.program_id IN (
    '10339d1d-239d-4e36-b524-8ce0fdf2d0c0',
    'a78e76d2-7e0b-4865-8013-0e037ebdc0f9',
    '482dee71-e4b9-4b42-a47b-3e16bb69e8f2',
    'a015ce08-a727-46c8-92d1-679b23338bc1',
    '98b7344e-cd44-4a99-9542-09dfdb11d31b'
        )

) AS enrolled
ON  
    viewed.user_id = enrolled.user_id
AND 
    enrolled.first_enrollment_time >= viewed.exposure_time
LEFT JOIN
    business_intelligence.user_activity_engagement_weekly engagement
ON
    viewed.user_id = engagement.user_id
AND
    enrolled.course_id = engagement.course_id
AND
    engagement.week = 'week_1';


--sumary of enrolls and engagement

SELECT 
    variation_name,
    SUM(has_verified) AS cnt_verifications, 
    COUNT(DISTINCT user_id) AS cnt_users
FROM 
    ahemphill.bundling_experiment_enrolls_engagement 
GROUP BY 
    1

--summary of transactions

SELECT 
    variation_name, 
    sum(bookings) AS sum_bookings, 
    count(1) AS cnt_transactions
FROM 
    ahemphill.bundling_experiment_transactions 
GROUP BY
    1

--manipulating data to understand ltv for bundles

SELECT 
    variation_name,
    has_verified,
    enrolled_course, 
    program_slot_number,
    course_seat_price,
    vtr,
    CASE WHEN course_verification_end_date <= current_date() THEN 1 ELSE 0 END AS has_verif_deadline_passed,
    COUNT(distinct user_id) AS cnt_users
FROM 
    ahemphill.bundling_experiment_enrolls_engagement a 
JOIN 
    course_master b
ON 
    a.enrolled_course = b.course_id
AND 
    enrolled_course is not null
JOIN 
    course_stats_summary c
ON 
    a.enrolled_course = c.course_id
GROUP BY 
    1,2,3,4,5,6,7
