-- DROP TABLE IF EXISTS ahemphill.engaged_users;
-- CREATE TABLE IF NOT EXISTS ahemphill.engaged_users AS

-- SELECT 
-- 	a.user_id, 
-- 	a.course_id,
-- 	b.weekly_engagement_level,
-- 	MIN(date) AS content_availability_date
-- FROM 
-- 	user_activity_engagement_daily a 
-- JOIN
-- 	user_activity_engagement_weekly b
-- ON 
-- 	a.week = 'week_1'
-- AND
-- 	a.week = b.week
-- AND
-- 	a.course_id = b.course_id
-- AND
-- 	a.user_id = b.user_id
-- GROUP BY
-- 	a.user_id, 
-- 	a.course_id,
-- 	b.weekly_engagement_level
-- HAVING
-- 	MIN(date) >= '2017-01-01'

DROP TABLE IF EXISTS ahemphill.engaged_users;
CREATE TABLE IF NOT EXISTS ahemphill.engaged_users AS

SELECT 
	date,
	a.user_id, 
	a.course_id,
	b.weekly_engagement_level
FROM 
	user_activity_engagement_daily a 
JOIN
	user_activity_engagement_weekly b
ON 
	a.week = 'week_1'
AND
	a.week = b.week
AND
	a.course_id = b.course_id
AND
	a.user_id = b.user_id
WHERE
	date >= '2017-01-01'


DROP TABLE IF EXISTS ahemphill.viable_users;
CREATE TABLE IF NOT EXISTS ahemphill.viable_users AS
SELECT
	username,
	user_id,
	dt
FROM
	curated.active_users_by_month a
JOIN
	production.d_user b
ON
	a.username = b.user_username
AND
	a.year = '2017';

DROP TABLE IF EXISTS ahemphill.reg_cohort_fy;
CREATE TABLE IF NOT EXISTS ahemphill.reg_cohort_fy AS
SELECT
	user_id,
	CASE
		WHEN user_account_creation_time BETWEEN '2011-07-01' AND '2012-06-30' THEN 2012 
		WHEN user_account_creation_time BETWEEN '2012-07-01' AND '2013-06-30' THEN 2013 
		WHEN user_account_creation_time BETWEEN '2013-07-01' AND '2014-06-30' THEN 2014 
		WHEN user_account_creation_time BETWEEN '2014-07-01' AND '2015-06-30' THEN 2015 
		WHEN user_account_creation_time BETWEEN '2015-07-01' AND '2016-06-30' THEN 2016 
		WHEN user_account_creation_time BETWEEN '2016-07-01' AND '2017-06-30' THEN 2017 
	END AS fiscal_year_reg
FROM
	production.d_user;

-- what % of viable users are new vs returning

SELECT 
	dt, 
	fiscal_year_reg, 
	COUNT(1) AS cnt_users
FROM 
	ahemphill.viable_users a
JOIN 
	ahemphill.reg_cohort_fy b
ON 
	a.user_id = b.user_id
GROUP BY 
	1,2

-- what % of viable users are coming from specific channels
SELECT
	dt,
	fiscal_year_reg,
	campaign_medium,
	campaign_source,
	campaign_name,
	campaign_content,
	COUNT(1) AS cnt_users
FROM
(
SELECT
	a.user_id,
	dt,
	timestamp,
	campaign_medium,
	campaign_source,
	campaign_name,
	campaign_content,
	c.fiscal_year_reg,
	row_number() OVER (partition by a.user_id order by timestamp ASC) AS rank
FROM
	ahemphill.viable_users a
JOIN
	utm_touch b
ON
	CAST(a.user_id AS VARCHAR) = CAST(b.user_id AS VARCHAR)
AND
	MONTH(dt) >= MONTH(b.timestamp)
JOIN
	ahemphill.reg_cohort_fy c
ON
	a.user_id = c.user_id
) a
WHERE
	rank = 1
-- AND
-- 	campaign_medium IN
-- 	(
-- 		'email',
-- 		'affiliate_partner',
-- 		'cpc',
-- 		'partner-marketing',
-- 		'paid-social',
-- 		'social-post',
-- 		'CHP',
-- 		'coursepage'
-- 	)
GROUP BY
	dt,
	campaign_medium,
	campaign_source,
	campaign_name,
	campaign_content,
	fiscal_year_reg;

-- what % of engaged users are new vs returning

SELECT 
	MONTH(date) AS dt,
	weekly_engagement_level, 
	fiscal_year_reg, 
	COUNT(1) AS cnt_users
FROM 
	user_activity_engagement_daily a
JOIN 
	ahemphill.reg_cohort_fy b
ON 
	a.user_id = b.user_id
AND
	a.week = 'week_1'
AND
	a.date >= '2017-01-01'
GROUP BY 
	1,2,3;


-- what % of engaged users are coming from specific channels

SELECT
	dt,
	weekly_engagement_level,
	campaign_medium,
	campaign_source,
	campaign_name,
	campaign_content,
	fiscal_year_reg,
	COUNT(1) AS cnt_users
FROM
(
	SELECT 
		MONTH(a.date) AS dt,
		campaign_medium,
		campaign_source,
		campaign_name,
		campaign_content,
		weekly_engagement_level, 
		fiscal_year_reg, 
		row_number() OVER (partition by a.user_id order by timestamp ASC) AS rank
	FROM 
		user_activity_engagement_daily a
	JOIN
		utm_touch b
	ON
		CAST(a.user_id AS VARCHAR) = CAST(b.user_id AS VARCHAR)
	AND
		MONTH(a.date) >= MONTH(b.timestamp)
	JOIN 
		ahemphill.reg_cohort_fy c
	ON 
		a.user_id = c.user_id
	AND
		a.week = 'week_1'
	AND
		a.date >= '2017-01-01'
) a 
WHERE
	rank = 1
-- AND
-- 	campaign_medium IN
-- 	(
-- 		'email',
-- 		'affiliate_partner',
-- 		'cpc',
-- 		'partner-marketing',
-- 		'paid-social',
-- 		'social-post',
-- 		'CHP',
-- 		'coursepage'
-- 	)
GROUP BY 
	dt,
	weekly_engagement_level,
		campaign_medium,
	campaign_source,
	campaign_name,
	campaign_content,
	fiscal_year_reg;


