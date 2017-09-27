-- Attribution model: Consider a 30 day window. Find all conversions within that "conversion" window. For each conversion, find the last campaign that was associated with the user and attribute the conversion to that campaign. Note that any campaign association that is detected 30 days prior to the event (even if it's the first event in the conversion window) is considerd for attribution purposes.


-- WHERE IS campaign_term?
-- are we missing screen events from mobile devices?
-- Do we run adds that open natively in the mobile app? If so, can we track attribution from those sources?
-- GA tracks referrals without UTM codes as well from common sources (google organic search etc)
-- I don't see source=google medium=cpc (presumably adwords data) in the segment logs, but do see it in GA
 
-- This is very important since we are doing a bunch of casting of strings to timestamps. This tells vertica what timezone the string is from.
SET TIME ZONE TO UTC;
 
 
-- Find all mappings from anonymous_ids to logged in user_ids, denormalize with username for convenience.
-- There should be one row here per anonymous_id that was seen in the month of August.
-- This allows us to "see into the future". If the anonymous user ever logs into the LMS in the month of august, we capture the mapping of that anonymous_id to their logged in user_id.
 
-- REVIEW: should be exactly one user_id for each anonymous_id, is this true?
DROP TABLE IF EXISTS ahemphill.identify;
CREATE TABLE ahemphill.identify AS
SELECT
  id.anonymous_id,
  COALESCE(du0.user_id, du1.user_id) AS user_id,
  COALESCE(du0.user_username, du1.user_username) AS username,
  id.domain
FROM (
  -- First extract the identify events because the join is not very performant and there aren't many of them
  SELECT DISTINCT
    anonymous_id,
    user_id, -- note that this can either be a numeric user_id like 1234 or a username like ""joeuser"", Otto emits segment events where the user_id is actually a username
    CASE WHEN POSITION('http' in url) > 0 THEN (CASE WHEN POSITION('.edx.org' IN SPLIT_PART(url, '/', 3)) > 0 THEN 'edx.org' ELSE SPLIT_PART(url, '/', 3) END) ELSE 'unknown' END AS domain
  FROM experimental_events_run14.event_records
  WHERE
    event_category='identify'
    AND anonymous_id IS NOT NULL
    AND user_id IS NOT NULL
) id
LEFT JOIN production.d_user du0 ON(CAST(du0.user_id AS VARCHAR) = id.user_id)
LEFT JOIN production.d_user du1 ON(du1.user_username = id.user_id) -- Otto emits events where the "user_id" is actually the user's username since we don't know the LMS internal user_id in our IDAs.
-- REVIEW: What happens if a username is also a valid numeric user_id like "12"?
;
-- Find all events that contain UTM codes. There should be one row here per page hit that included UTM parameters in the query string.
DROP TABLE IF EXISTS ahemphill.utm_touch;
CREATE TABLE ahemphill.utm_touch AS
SELECT
  CAST(e.timestamp AS TIMESTAMPTZ) AS timestamp, -- note that timestamp is somewhat irregular, source of error is unknown
  -- REVIEW: figure out what to do about timestamp! Should we be using received_at?
  e.user_id,
  e.anonymous_id,
  e.project,
  e.path,
  e.search,
  e.referrer,   -- This is different for tracking log events.
  split_part(e.referrer, '/', 3) AS referring_domain,
  e.agent_type,
  e.agent_os,
  CASE WHEN POSITION('http' in e.url) > 0 THEN (CASE WHEN POSITION('.edx.org' IN SPLIT_PART(e.url, '/', 3)) > 0 THEN 'edx.org' ELSE SPLIT_PART(e.url, '/', 3) END) ELSE 'unknown' END AS domain,
  e.campaign_source,
  e.campaign_medium,
  e.campaign_content,
  e.campaign_name
FROM experimental_events_run14.event_records e
WHERE
  e.event_type = 'page'
  AND e.campaign_source != 'marketing_site_worker'
  AND (e.campaign_source IS NOT NULL
       OR e.campaign_medium IS NOT NULL
       OR e.campaign_content IS NOT NULL
       OR e.campaign_name IS NOT NULL)
;
 
-- This table takes a stab at identifying the referrer at "entry points" into the edX system.
DROP TABLE IF EXISTS ahemphill.utm_referral;
CREATE TABLE ahemphill.utm_referral AS
SELECT
  CAST(e.timestamp AS TIMESTAMPTZ) AS timestamp,
  e.user_id,
  e.anonymous_id,
  e.project,
  e.url,
  e.path,
  e.search,
  REGEXP_SUBSTR(e.search, 'gclid=([^&]+)', 1, 1, '', 1) AS google_click_id,
  e.referrer,   -- This is different for tracking log events.
  SPLIT_PART(e.referrer, '/', 3) AS referring_domain,
  e.agent_type,
  e.agent_os,
  CASE WHEN POSITION('http' in e.url) > 0 THEN (CASE WHEN POSITION('.edx.org' IN SPLIT_PART(e.url, '/', 3)) > 0 THEN 'edx.org' ELSE SPLIT_PART(e.url, '/', 3) END) ELSE 'unknown' END AS domain
FROM experimental_events_run14.event_records e
WHERE
  e.event_type = 'page'
  AND split_part(e.referrer, '/', 3) NOT ILIKE '%edx.org%'
  AND split_part(e.referrer, '/', 3) NOT IN ('mitprofessionalx.mit.edu', 'courses.harvardxplus.harvard.edu')
  AND e.referrer IS NOT NULL
  AND e.referrer != ''
  AND e.campaign_source IS NULL
;
 
 
 
-- AdWords Campaign clicks do not include UTM parameters in the URL, instead they append a "gclid" parameter, so we have to grab those touches from the referral data and manufacture UTM parameters for them.
INSERT INTO ahemphill.utm_touch
(timestamp, user_id, anonymous_id, project, path, search, referrer, referring_domain, agent_type, agent_os, domain, campaign_source, campaign_medium, campaign_content, campaign_name)
SELECT
  r.timestamp,
  r.user_id,
  r.anonymous_id,
  r.project,
  r.path,
  r.search,
  r.referrer,
  r.referring_domain,
  r.agent_type,
  r.agent_os,
  r.domain,
  'google',
  'cpc',
  NULL AS campaign_content,
  NULL AS campaign_name
FROM ahemphill.utm_referral r
WHERE
  r.google_click_id IS NOT NULL
;
 
 
-- Gather the first enrollment event for each (user_id, course_id). This will capture any new enrollments, not upgrades. Note that there should be one row
-- per (user_id, course_id). Upgrade to paid tracks is tracked as a separate conversion.
DROP TABLE IF EXISTS ahemphill.utm_course_enroll;
CREATE TABLE ahemphill.utm_course_enroll AS
SELECT DISTINCT
  FIRST_VALUE(CAST(e.timestamp AS TIMESTAMPTZ)) OVER (PARTITION BY e.user_id, e.course_id ORDER BY CAST(e.timestamp AS TIMESTAMPTZ) ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS timestamp,
  FIRST_VALUE(CASE WHEN POSITION('.edx.org' IN host) > 0 THEN 'edx.org' ELSE host END) OVER (PARTITION BY e.user_id, e.course_id ORDER BY CAST(e.timestamp AS TIMESTAMPTZ) ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS domain,
  e.user_id,
  e.course_id,
  FIRST_VALUE(e.mode) OVER (PARTITION BY e.user_id, e.course_id ORDER BY CAST(e.timestamp AS TIMESTAMPTZ) ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS mode,
  LAST_VALUE(CAST(e.timestamp AS TIMESTAMPTZ)) OVER (PARTITION BY e.user_id, e.course_id ORDER BY CAST(e.timestamp AS TIMESTAMPTZ) ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_enrollment_timestamp
FROM experimental_events_run14.event_records e
WHERE
  e.event_type = 'edx.course.enrollment.activated'
  AND e.project = 'tracking_prod'
;
 
-- For each enrollment within the window, try to find a UTM touch for any anonymous_id that has ever been associated with the enrolled user. Grab the last UTM touch for each user.
DROP TABLE IF EXISTS ahemphill.utm_course_enroll_attribution;
CREATE TABLE ahemphill.utm_course_enroll_attribution AS
SELECT DISTINCT
  v.timestamp AS enroll_time,
  v.user_id,
  v.course_id,
  v.mode,
  v.last_enrollment_timestamp,
  v.domain,
  LAST_VALUE(u.anonymous_id) OVER (PARTITION BY v.user_id, v.course_id ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS anonymous_id,
  LAST_VALUE(u.timestamp) OVER (PARTITION BY v.user_id, v.course_id ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_touch_timestamp,
  LAST_VALUE(u.referring_domain) OVER (PARTITION BY v.user_id, v.course_id ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS referring_domain,
  LAST_VALUE(u.path) OVER (PARTITION BY v.user_id, v.course_id ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS landing_page,
  LAST_VALUE(u.campaign_source) OVER (PARTITION BY v.user_id, v.course_id ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_source,
  LAST_VALUE(u.campaign_medium) OVER (PARTITION BY v.user_id, v.course_id ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_medium,
  LAST_VALUE(u.campaign_content) OVER (PARTITION BY v.user_id, v.course_id ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_content,
  LAST_VALUE(u.campaign_name) OVER (PARTITION BY v.user_id, v.course_id ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_name
FROM ahemphill.utm_course_enroll v
INNER JOIN ahemphill.identify i ON (i.user_id = v.user_id AND i.domain = v.domain)
INNER JOIN ahemphill.utm_touch u ON (u.anonymous_id = i.anonymous_id AND u.domain = v.domain AND u.timestamp < v.timestamp AND DATEDIFF(day, v.timestamp, u.timestamp) > -60)
--WHERE
--  v.timestamp > (TIMESTAMP '2016-09-01 00:00:00' - INTERVAL '60 days')
--  AND v.timestamp < '2016-09-01 00:00:00'
;
 
-- Find any registration event that has occurred. Every user should have exactly one registration event, so don't look for the first or the last. REVIEW: test this hypothesis!
DROP TABLE IF EXISTS ahemphill.utm_registration;
CREATE TABLE ahemphill.utm_registration AS
SELECT
  CAST(e.timestamp AS TIMESTAMPTZ) AS timestamp,
  e.user_id
FROM experimental_events_run14.event_records e
WHERE
  (e.event_type = 'edx.bi.user.account.registered'
   AND e.project = 'hqawk62tyf') -- REVIEW: human readable project name
  -- THIS WON'T CAPTURE MOBILE REGISTRATIONS!!!!
;
 
 
-- Look for the last UTM touch before the registration event for each user.
DROP TABLE IF EXISTS ahemphill.utm_registration_attribution;
CREATE TABLE ahemphill.utm_registration_attribution AS
SELECT DISTINCT
  v.user_id,
  v.timestamp AS registration_time,
  LAST_VALUE(u.anonymous_id) OVER (PARTITION BY v.user_id ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS anonymous_id,
  LAST_VALUE(u.timestamp) OVER (PARTITION BY v.user_id ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_touch_timestamp,
  LAST_VALUE(u.domain) OVER (PARTITION BY v.user_id ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS domain,
  LAST_VALUE(u.referring_domain) OVER (PARTITION BY v.user_id ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS referring_domain,
  LAST_VALUE(u.path) OVER (PARTITION BY v.user_id ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS landing_page,
  LAST_VALUE(u.campaign_source) OVER (PARTITION BY v.user_id ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_source,
  LAST_VALUE(u.campaign_medium) OVER (PARTITION BY v.user_id ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_medium,
  LAST_VALUE(u.campaign_content) OVER (PARTITION BY v.user_id ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_content,
  LAST_VALUE(u.campaign_name) OVER (PARTITION BY v.user_id ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_name
FROM ahemphill.utm_registration v
INNER JOIN ahemphill.identify i ON (i.user_id = v.user_id)
INNER JOIN ahemphill.utm_touch u ON (u.anonymous_id = i.anonymous_id AND u.timestamp < v.timestamp AND DATEDIFF(day, v.timestamp, u.timestamp) > -60)
--WHERE
--  v.timestamp > (TIMESTAMP '2016-09-23 00:00:00' - INTERVAL '30 days')
--  AND v.timestamp < '2016-09-23 00:00:00'
;
 
 
-- Find all purchases of seats and group the transactions by course_id and mode. Note this does not take into account refunds!
DROP TABLE IF EXISTS ahemphill.utm_transactions;
CREATE TABLE ahemphill.utm_transactions AS
SELECT
  t.order_timestamp,
  u.user_id,
  t.order_course_id,
  t.order_product_detail,
  t.payment_ref_id,
  t.transaction_amount_per_item,
  t.order_line_item_quantity,
  LOWER(t.partner_short_code) AS 'partner_short_code',
  CASE LOWER(t.partner_short_code) WHEN 'mitpe' THEN 'mitprofessionalx.mit.edu' WHEN 'hxplus' THEN 'courses.harvardxplus.harvard.edu' ELSE 'edx.org' END AS 'domain'
FROM finance.f_orderitem_transactions t
LEFT JOIN production.d_user u ON u.user_username = t.order_username
WHERE
  t.transaction_type = 'sale'
  AND t.order_course_id IS NOT NULL
  AND t.order_timestamp >= '2016-07-11 00:00:00' -- this is the first day for which we have events in vertica
;
-- REVIEW: a better purchase event? or add the columns to the spike table for the "Completed Order" event?
 
-- select CAST(t.order_timestamp AS DATE), sum(t.transaction_amount_per_item), sum(t.order_line_item_quantity) from ahemphill.utm_transactions t group by 1 order by 1 desc;
-- select sum(t.transaction_amount_per_item) from ahemphill.utm_transactions t;
 
-- Look for the most recent UTM touch prior to the transaction.
DROP TABLE IF EXISTS ahemphill.utm_transaction_attribution;
CREATE TABLE ahemphill.utm_transaction_attribution AS
SELECT DISTINCT
  v.user_id,
  v.order_course_id AS 'course_id',
  v.order_product_detail AS 'mode',
  v.order_timestamp AS transaction_time,
  v.payment_ref_id,
  v.transaction_amount_per_item AS net_bookings,
  v.partner_short_code,
  v.domain,
  LAST_VALUE(u.anonymous_id) OVER (PARTITION BY v.user_id, v.order_course_id, v.order_product_detail ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS anonymous_id,
  LAST_VALUE(u.timestamp) OVER (PARTITION BY v.user_id, v.order_course_id, v.order_product_detail ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_touch_timestamp,
  LAST_VALUE(u.referring_domain) OVER (PARTITION BY v.user_id, v.order_course_id, v.order_product_detail ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS referring_domain,
  LAST_VALUE(u.path) OVER (PARTITION BY v.user_id, v.order_course_id, v.order_product_detail ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS landing_page,
  LAST_VALUE(u.campaign_source) OVER (PARTITION BY v.user_id, v.order_course_id, v.order_product_detail ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_source,
  LAST_VALUE(u.campaign_medium) OVER (PARTITION BY v.user_id, v.order_course_id, v.order_product_detail ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_medium,
  LAST_VALUE(u.campaign_content) OVER (PARTITION BY v.user_id, v.order_course_id, v.order_product_detail ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_content,
  LAST_VALUE(u.campaign_name) OVER (PARTITION BY v.user_id, v.order_course_id, v.order_product_detail ORDER BY u.timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_name
FROM ahemphill.utm_transactions v
JOIN ahemphill.identify i ON (i.user_id = v.user_id)
JOIN ahemphill.utm_touch u ON (u.anonymous_id = i.anonymous_id AND u.timestamp < v.order_timestamp AND DATEDIFF(day, v.order_timestamp, u.timestamp) > -60 AND u.domain = v.domain)


DROP TABLE IF EXISTS ahemphill.campaign_conversions;
CREATE TABLE ahemphill.campaign_conversions AS
SELECT
  domain AS 'partner',
  transaction_time AS 'conversion_time',
  last_touch_timestamp AS 'last_touch_time',
  'transaction' AS 'conversion_type',
  anonymous_id,
  CAST(user_id AS INTEGER) as user_id,
  referring_domain,
  landing_page,
  course_id,
  campaign_source,
  campaign_medium,
  campaign_name,
  net_bookings
FROM ahemphill.utm_transaction_attribution
UNION ALL
SELECT
  domain AS 'partner',
  enroll_time AS 'conversion_time',
  last_touch_timestamp AS 'last_touch_time',
  'enrollment',
  anonymous_id,
  CAST(user_id AS INTEGER) as user_id,
  referring_domain,
  landing_page,
  course_id, 
  campaign_source,
  campaign_medium,
  campaign_name,
  CAST(NULL AS FLOAT)
FROM ahemphill.utm_course_enroll_attribution
UNION ALL
SELECT
  domain AS 'partner',
  registration_time AS 'conversion_time',
  last_touch_timestamp AS 'last_touch_time',
  'registration',
  anonymous_id,
  CAST(user_id AS INTEGER) as user_id,
  referring_domain,
  landing_page,
  NULL,
  campaign_source,
  campaign_medium,
  campaign_name,
  CAST(NULL AS FLOAT)
FROM ahemphill.utm_registration_attribution
;

DROP TABLE IF EXISTS ahemphill.campaign_performance_by_course;
CREATE TABLE ahemphill.campaign_performance_by_course AS
SELECT
  partner,
  campaign_source,
  campaign_medium,
  campaign_name,
  landing_page,
  course_id,
  SUM(CASE WHEN conversion_type='enrollment' THEN 1 ELSE 0 END) AS 'enrollments',
  SUM(CASE WHEN conversion_type='registration' THEN 1 ELSE 0 END) AS 'registrations',
  SUM(CASE WHEN conversion_type='transaction' THEN 1 ELSE 0 END) AS 'transactions',
  SUM(CASE WHEN conversion_type='transaction' THEN net_bookings ELSE 0 END) AS 'net_bookings'
FROM ahemphill.campaign_conversions
GROUP BY 1, 2, 3, 4, 5, 6
;

DROP TABLE IF EXISTS ahemphill.campaign_performance_by_hour;
CREATE TABLE ahemphill.campaign_performance_by_hour AS
SELECT
  TO_CHAR(conversion_time, 'YYYY-MM-DD HH')||':00:00' AS 'hour of date',
  partner,
  campaign_source,
  campaign_medium,
  campaign_name,
  landing_page,
  SUM(CASE WHEN conversion_type='enrollment' THEN 1 ELSE 0 END) AS 'enrollments',
  SUM(CASE WHEN conversion_type='registration' THEN 1 ELSE 0 END) AS 'registrations',
  SUM(CASE WHEN conversion_type='transaction' THEN 1 ELSE 0 END) AS 'transactions',
  SUM(CASE WHEN conversion_type='transaction' THEN net_bookings ELSE 0 END) AS 'net_bookings'
FROM ahemphill.campaign_conversions
GROUP BY 1, 2, 3, 4, 5, 6
;


