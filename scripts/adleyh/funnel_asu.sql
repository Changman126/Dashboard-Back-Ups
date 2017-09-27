---------------------------
-- Exploring the event data
---------------------------

-- explore identify calls. which identifiers are present on which events?
SELECT count(*), anon, uid, username
FROM
(
SELECT
        case when anonymous_id IS NOT NULL then 1 else 0 end anon, 
        case when user_id IS NOT NULL then 1 else 0 end uid, 
        case when username IS NOT NULL then 1 else 0 end username
FROM experimental_events_run14.event_records
WHERE event_category='identify' 
) as iq
GROUP BY anon, uid, username
;

-- Find ASU courses and figure out how to isolate them with course ID
SELECT *
FROM production.d_course
WHERE course_id LIKE '%ASUx%' -- use this to identify ASU course IDs
;

-- Find ASU marketing pages and figure out how to identify them
-- From browsing the site, all ASU course about pages contain '-asux-'
-- Note that the ASUx series page (dog behavior) will not be included since the URL does not follow this structure, however each individual course page does

SELECT *
FROM experimental_events_run14.event_records e
WHERE e.path LIKE '/course/%' AND e.path LIKE '%asux%'
LIMIT 100
;

-- see event_categories: include all events? or limit to page events? LIMIT TO PAGE EVENTS
SELECT event_category, count(*)
FROM experimental_events_run14.event_records e
WHERE e.path LIKE '/course/%' AND e.path LIKE '%asux%'
GROUP BY event_category
;



-- ugh -- should have checked this before, but changing time stamp interval isn't quite right
SELECT TIMESTAMPDIFF('minute', '2016-07-15', '2016-07-01');

-- user this interval instead -- 43200 minutes in a month (if events happen out of order by less than a minute, will include them. this seems fine)
SELECT TIMESTAMPDIFF('minute', '2016-07-01', '2016-07-31');

---------------------------
-- ASU funnel -- made by modifying Gabe's query
---------------------------

-- First we construct a table that maps an anoymous_id to the user's eventual "real" user_id, if they ever login to the LMS/Otto etc
DROP TABLE IF EXISTS kwillemin.identify;
CREATE TABLE kwillemin.identify AS
SELECT
  id.anonymous_id,
  COALESCE(du0.user_id, du1.user_id) AS user_id,
  COALESCE(du0.user_username, du1.user_username) AS username
FROM (
  -- First extract the identify events because the join is not very performant and there aren't many of them
  SELECT
    DISTINCT anonymous_id,
    user_id -- note that this can either be a numeric user_id like 1234 or a username like "joeuser", Otto emits segment events where the user_id is actually a username
  FROM experimental_events_run14.event_records
  WHERE event_category='identify' AND user_id IS NOT NULL AND anonymous_id IS NOT NULL
)id
LEFT JOIN production.d_user du0 ON(CAST(du0.user_id AS VARCHAR) = id.user_id)
LEFT JOIN production.d_user du1 ON(du1.user_username = id.user_id)
;

SELECT * FROM kwillemin.identify
;


-- This method is heavily inspired by https://looker.com/blog/modeling-conversion-funnels-in-looker-a-mysql-subselect-approach

-- This funnel is targetted at the purchase flow for a single course: course-v1:ETSx+TOEFLx+2T2016.
-- There are many parts of this we might want to make dynamic or to group by instead of hardcoding values for.

-- The first stage of the funnel identifies users who viewed the product page.
-- Normally we would specify some kind of time interval here to only show users who viewed it within that interval.
-- In this case the event table only contains one week of data, so it's already time constrained.
-- This table will contain the identifier for each user and the time of their first access of the product page.

DROP TABLE IF EXISTS kwillemin.funnel_stage1_ASU;
CREATE TABLE kwillemin.funnel_stage1_ASU AS
SELECT
  product_page.visitor_id,
  MIN(product_page.access_time) AS product_page_time -- since we group by visitor_id, this is the first time they accessed the product page in the week
FROM (
  SELECT
    COALESCE(CAST(i.user_id AS VARCHAR), e.anonymous_id) AS visitor_id, -- users who eventually login will have a visitor_id that is their numeric user_id, users who don't will just have their anonymous_id
    CAST(e.timestamp AS TIMESTAMPTZ) AS access_time -- the data in the event table is currently just a string so we cast it to a native timestamp field
  FROM experimental_events_run14.event_records e
  LEFT JOIN kwillemin.identify i ON (i.anonymous_id = e.anonymous_id) -- assumes segment events all have anonymous_id, not sure if that's valid or not
  WHERE
    e.path LIKE '/course/%' AND e.path LIKE '%asux%'
    -- e.path='/course/toeflr-test-preparation-insiders-guide-etsx-toeflx' -- I found this by querying for events that looked like product page hits, not sure if we have a mapping somewhere like the drupal db?
    AND e.event_category = 'page' -- KW added this restriction 
    AND e.timestamp IS NOT NULL  -- not sure how this can happen?!?!
    AND e.project = 'hqawk62tyf' -- this is the "prod-lms" segment.com project
) product_page
GROUP BY 1;

-- summary ASU about page FIRST views (unique users) -- use to ROUGHLY match against GA new user sessions by date on ASU course pages
-- hard to say, but general pattern matches, e.g., peak on 8/16
SELECT date(product_page_time), count(*)
FROM kwillemin.funnel_stage1_ASU
GROUP BY date(product_page_time)
ORDER BY date(product_page_time) ASC
;

-- Figure out how to find ASU course
SELECT *
FROM experimental_events_run14.event_records e
WHERE path LIKE '%/course_modes/choose/%' AND path LIKE '%ASUx%' AND event_category = 'page'
LIMIT 100
;

-- The goal of this stage is to pass through the result from stage1 and append a column that represents the first time they accessed the course mode selection page *after* their first access of the product page.
DROP TABLE IF EXISTS kwillemin.funnel_stage2_ASU;
CREATE TABLE kwillemin.funnel_stage2_ASU AS
SELECT
  stage1.visitor_id,
  MIN(stage1.product_page_time) AS product_page_time, -- Given the way this join is structured, this should always have the same value, we could techinically group by 1, 2
  MIN(course_mode.access_time) AS course_mode_time -- This will be the first time the user accessed the course mode page after viewing the product page
FROM kwillemin.funnel_stage1_ASU stage1
LEFT JOIN (
    SELECT
      COALESCE(CAST(i.user_id AS VARCHAR), e.anonymous_id) AS visitor_id,
      CAST(e.timestamp AS TIMESTAMPTZ) AS access_time
    FROM experimental_events_run14.event_records e
    LEFT JOIN kwillemin.identify i ON (i.anonymous_id = e.anonymous_id)
    WHERE path LIKE '%/course_modes/choose/%' AND path LIKE '%ASUx%' AND event_category = 'page'
      -- path IN ('/course_modes/choose/course-v1:ETSx+TOEFLx+2T2016/', '/course_modes/choose/course-v1:ETSx%20TOEFLx%202T2016/') -- This was discovered by querying pages that looked like '%TOEFL%'
      AND e.project='hqawk62tyf'
      AND e.timestamp IS NOT NULL
) course_mode ON (course_mode.visitor_id = stage1.visitor_id 
      AND TIMESTAMPDIFF('minute', stage1.product_page_time, course_mode.access_time) BETWEEN 0 AND 43200) -- FYI, between is INCLUSIVE
      -- AND TIMESTAMPDIFF('second', stage1.product_page_time, course_mode.access_time) BETWEEN 0 AND 86400) -- only include course mode accesses that occur within 1 day of the product page visit
GROUP BY 1
;

SELECT * FROM kwillemin.funnel_stage2_ASU
;

-- If the user indicates they want a verified cert on the course mode page, they will be taken to the basket in Otto.
DROP TABLE IF EXISTS kwillemin.funnel_stage3_ASU;
CREATE TABLE kwillemin.funnel_stage3_ASU AS
SELECT
    stage2.visitor_id,
    MIN(stage2.product_page_time) AS product_page_time,
    MIN(stage2.course_mode_time) AS course_mode_time,
    MIN(basket.access_time) AS basket_time
FROM kwillemin.funnel_stage2_ASU stage2
LEFT JOIN (
    SELECT
      COALESCE(CAST(i.user_id AS VARCHAR), e.anonymous_id) AS visitor_id,
      CAST(e.timestamp AS TIMESTAMPTZ) AS access_time
    FROM experimental_events_run14.event_records e
    LEFT JOIN kwillemin.identify i ON (i.anonymous_id = e.anonymous_id)
    WHERE
      e.path='/basket/' -- we may want to consider using the full URL here instead of just the path
      AND e.course_id LIKE '%ASUx%' -- This property is filled in by Otto, not sure how it would work if there were multiple courses in the basket?!?!
      -- AND e.course_id='course-v1:ETSx+TOEFLx+2T2016' -- This property is filled in by Otto, not sure how it would work if there were multiple courses in the basket?!?!
      AND e.timestamp IS NOT NULL
      AND e.project = 'GHEUdjuJS4' -- This is the segment.com project ID for Otto
) basket ON (basket.visitor_id = stage2.visitor_id 
      -- AND TIMESTAMPDIFF('second', stage2.course_mode_time, basket.access_time) BETWEEN 0 AND 86400) -- again, only count a basket access if it occurs within 1 day of the course mode page access
      AND TIMESTAMPDIFF('minute', stage2.course_mode_time, basket.access_time) BETWEEN 0 AND 43200) -- FYI, between is INCLUSIVE
GROUP BY 1;

SELECT * FROM kwillemin.funnel_stage3_ASU
;

-- The basket has buttons at the bottom that allow you to choose if you want to pay with cybersource or paypal. I used the chrome dev tools to see which events are emitted when you click those buttons.
-- They both emit the same event and then redirect to either paypal or cybersource. I don't actually see a way to differentiate between a paypal click or a cybersource click.
DROP TABLE IF EXISTS kwillemin.funnel_stage4_ASU;
CREATE TABLE kwillemin.funnel_stage4_ASU AS
SELECT
  stage3.visitor_id,
  MIN(stage3.product_page_time) AS product_page_time,
  MIN(stage3.course_mode_time) AS course_mode_time,
  MIN(stage3.basket_time) AS basket_time,
  MIN(click_pay.access_time) AS click_pay_time
FROM kwillemin.funnel_stage3_ASU stage3
LEFT JOIN (
  SELECT
    COALESCE(CAST(i.user_id AS VARCHAR), e.anonymous_id) AS visitor_id,
    CAST(e.timestamp AS TIMESTAMPTZ) AS access_time
  FROM experimental_events_run14.event_records e
  LEFT JOIN kwillemin.identify i ON (i.anonymous_id = e.anonymous_id)
  WHERE
    e.event_type='edx.bi.ecommerce.basket.payment_selected'
    AND e.course_id LIKE '%ASUx%'
    -- AND e.course_id='course-v1:ETSx+TOEFLx+2T2016'
    AND e.timestamp IS NOT NULL
    AND e.project = 'GHEUdjuJS4'
) click_pay ON (click_pay.visitor_id = stage3.visitor_id AND TIMESTAMPDIFF('minute', stage3.basket_time, click_pay.access_time) BETWEEN 0 AND 43200)
GROUP BY 1;

SELECT * FROM kwillemin.funnel_stage4_ASU
;

-- If the user completes the checkout process, then Otto will upgrade them to Verified. Look for that upgrade event.
DROP TABLE IF EXISTS kwillemin.funnel_stage5_ASU;
CREATE TABLE kwillemin.funnel_stage5_ASU AS
SELECT
  stage4.visitor_id,
  MIN(stage4.product_page_time) AS product_page_time,
  MIN(stage4.course_mode_time) AS course_mode_time,
  MIN(stage4.basket_time) AS basket_time,
  MIN(stage4.click_pay_time) AS click_pay_time,
  MIN(verified.access_time) AS verified_time
FROM kwillemin.funnel_stage4_ASU stage4
LEFT JOIN (
  SELECT
    COALESCE(CAST(e.user_id AS VARCHAR), e.user_id) AS visitor_id,
    CAST(e.timestamp AS TIMESTAMPTZ) AS access_time
  FROM experimental_events_run14.event_records e
  WHERE
    e.event_type='edx.course.enrollment.mode_changed'
    AND mode='verified'
    AND e.course_id LIKE '%ASUx%'
    -- AND e.course_id='course-v1:ETSx+TOEFLx+2T2016'
    AND e.timestamp IS NOT NULL
    AND e.project = 'tracking_prod'
) verified ON (verified.visitor_id = stage4.visitor_id AND TIMESTAMPDIFF('minute', stage4.click_pay_time, verified.access_time) BETWEEN 0 AND 43200)
GROUP BY 1;

SELECT * FROM kwillemin.funnel_stage5_ASU
;

-- Finally you have a table that contains visitor_ids and the subsequent access times of each stage of the funnel. If the visitor fell out of the funnel they will have NULL values in each column after the point of drop off.
SELECT
  SUM(CASE WHEN product_page_time IS NULL THEN 0 ELSE 1 END) as product_page_users,
  SUM(CASE WHEN course_mode_time IS NULL THEN 0 ELSE 1 END) as course_mode_users,
  SUM(CASE WHEN basket_time IS NULL THEN 0 ELSE 1 END) as basket_users,
  SUM(CASE WHEN click_pay_time IS NULL THEN 0 ELSE 1 END) as click_pay_users,
  SUM(CASE WHEN verified_time IS NULL THEN 0 ELSE 1 END) as purchased_users
FROM kwillemin.funnel_stage5_ASU
;


---------------------------
-- Check number of events/unique users to get a sense of how many people are dropping out of funnel by forcing sequential completion
---------------------------

-- 1. Course about page views
SELECT count(*), count(distinct anonymous_id), count(distinct user_id), count(distinct username), count(distinct anonymous_id user_id)
FROM experimental_events_run14.event_records e
WHERE e.path LIKE '/course/%' AND e.path LIKE '%asux%'
        AND e.event_category = 'page'
        AND  e.timestamp IS NOT NULL
        AND e.project = 'hqawk62tyf' 
;


-- 2. Mode selection page (i.e., they clicked enroll)
SELECT count(*), count(distinct anonymous_id), count(distinct user_id), count(distinct username)
FROM experimental_events_run14.event_records e
WHERE path LIKE '%/course_modes/choose/%' AND path LIKE '%ASUx%' 
        AND event_category = 'page'
        AND e.project='hqawk62tyf'
        AND e.timestamp IS NOT NULL
;


-- 3. Reached basket page
SELECT count(*), count(distinct anonymous_id), count(distinct user_id), count(distinct username)
FROM experimental_events_run14.event_records e
WHERE
      e.path='/basket/' -- we may want to consider using the full URL here instead of just the path
      AND e.course_id LIKE '%ASUx%' -- This property is filled in by Otto, not sure how it would work if there were multiple courses in the basket?!?!
      AND e.timestamp IS NOT NULL
      AND e.project = 'GHEUdjuJS4' -- This is the segment.com project ID for Otto


-- 4. Clicked Pay
SELECT count(*), count(distinct anonymous_id), count(distinct user_id), count(distinct username)
FROM experimental_events_run14.event_records e
WHERE
    e.event_type='edx.bi.ecommerce.basket.payment_selected'
    AND e.course_id LIKE '%ASUx%'
    AND e.timestamp IS NOT NULL
    AND e.project = 'GHEUdjuJS4'
;

-- 5. check how many ASU upgrade events there are (without limiting to funnel)
SELECT count(*), count(distinct anonymous_id), count(distinct user_id), count(distinct username)
        -- event_type, event_source, event_category, timestamp, date, referrer, anonymous_id, user_id, username, course_id, mode, created
FROM experimental_events_run14.event_records
WHERE event_type = 'edx.course.enrollment.mode_changed'
        -- AND course_id LIKE '%ASUx%'
        AND mode = 'verified'
;

-- RUNNING IN LMS shows that 417 verified mode records created after
/*
SELECT *
FROM student_courseenrollment e
WHERE course_id LIKE '%ASUx%' AND mode = 'verified'
and created >= '2016-07-11'