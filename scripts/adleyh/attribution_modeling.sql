
DROP TABLE ahemphill.utm_first_touch_daily;
CREATE TABLE ahemphill.utm_first_touch_daily AS
SELECT
	date,
	user_id,
	anonymous_id,
	campaign_source,
	campaign_medium,
	campaign_name,
	timestamp
FROM
(
SELECT
	date,
	user_id,
	anonymous_id,
	campaign_source,
	campaign_medium,
	campaign_name,
	timestamp,
	ROW_NUMBER() OVER (PARTITION BY date, user_id ORDER BY timestamp ASC) AS rank
FROM 
	utm_touch
) a
WHERE
	rank = 1;

DROP TABLE IF EXISTS ahemphill.utm_first_touch_daily_enrolls;
CREATE TABLE IF NOT EXISTS ahemphill.utm_first_touch_daily_enrolls AS
SELECT
	a.date,
	a.user_id,
	a.campaign_source,
	a.campaign_medium,
	a.campaign_name,
	a.timestamp,
	b.course_id,
	d.user_account_creation_time,
	b.first_enrollment_time,
	c.first_verified_enrollment_time,
	DATEDIFF('day', date, date(user_account_creation_time)) AS days_from_utm_touch_reg,
	CASE
		WHEN d.user_id IS NOT NULL
		THEN ROW_NUMBER() OVER (PARTITION BY COALESCE(a.user_id, anonymous_id)
			ORDER BY DATEDIFF('day', date, date(user_account_creation_time)) DESC)
		ELSE
			ROW_NUMBER() OVER (PARTITION BY COALESCE(a.user_id, anonymous_id)
			ORDER BY date DESC)
	END AS rank_first_touch_reg,
	CASE
		WHEN d.user_id IS NOT NULL
		THEN ROW_NUMBER() OVER (PARTITION BY COALESCE(a.user_id, anonymous_id)
			ORDER BY DATEDIFF('day', date, date(user_account_creation_time)) ASC)
		ELSE
			ROW_NUMBER() OVER (PARTITION BY COALESCE(a.user_id, anonymous_id)
			ORDER BY date ASC)
	END AS rank_last_touch_reg,
	DATEDIFF('day', date, b.first_enrollment_time) AS days_from_utm_touch_enroll,
	CASE
		WHEN b.course_id IS NOT NULL
		THEN ROW_NUMBER() OVER (PARTITION BY COALESCE(a.user_id, anonymous_id), b.course_id 
			ORDER BY DATEDIFF('day', date, b.first_enrollment_time) DESC)
		ELSE
			ROW_NUMBER() OVER (PARTITION BY COALESCE(a.user_id, anonymous_id), b.course_id 
			ORDER BY date DESC)
	END AS rank_first_touch_enroll,
	CASE
		WHEN b.course_id IS NOT NULL
		THEN ROW_NUMBER() OVER (PARTITION BY COALESCE(a.user_id, anonymous_id), b.course_id 
			ORDER BY DATEDIFF('day', date, b.first_enrollment_time) ASC)
		ELSE
			ROW_NUMBER() OVER (PARTITION BY COALESCE(a.user_id, anonymous_id), b.course_id 
			ORDER BY date ASC)
	END AS rank_last_touch_enroll,
	DATEDIFF('day', date, c.first_verified_enrollment_time) AS days_from_utm_touch_verify,
	CASE
		WHEN c.course_id IS NOT NULL
		THEN ROW_NUMBER() OVER (PARTITION BY COALESCE(a.user_id, anonymous_id), c.course_id 
			ORDER BY DATEDIFF('day', date, c.first_verified_enrollment_time) DESC)
		ELSE
			ROW_NUMBER() OVER (PARTITION BY COALESCE(a.user_id, anonymous_id), c.course_id 
			ORDER BY date DESC)
	END AS rank_first_touch_verify,
	CASE
		WHEN c.course_id IS NOT NULL
		THEN ROW_NUMBER() OVER (PARTITION BY COALESCE(a.user_id, anonymous_id), c.course_id 
			ORDER BY DATEDIFF('day', date, c.first_verified_enrollment_time) ASC)
		ELSE
			ROW_NUMBER() OVER (PARTITION BY COALESCE(a.user_id, anonymous_id), c.course_id 
			ORDER BY date ASC)
	END AS rank_last_touch_verify
FROM
	ahemphill.utm_first_touch_daily a
LEFT JOIN
	production.d_user_course b
ON 
	CAST(a.user_id AS VARCHAR) = CAST(b.user_id AS VARCHAR)
AND 
	a.date <= DATE(b.first_enrollment_time)
AND 
	DATEDIFF('day', date, b.first_enrollment_Time) <= 30
LEFT JOIN
	production.d_user_course c
ON 
	CAST(a.user_id AS VARCHAR) = CAST(c.user_id AS VARCHAR)
AND 
	a.date <= DATE(c.first_verified_enrollment_time)
AND 
	DATEDIFF('day', date, c.first_verified_enrollment_time) <= 30
LEFT JOIN
	production.d_user d
ON 
	CAST(a.user_id AS VARCHAR) = CAST(d.user_id AS VARCHAR)
AND 
	a.date <= DATE(d.user_account_creation_time)
AND 
	DATEDIFF('day', date, d.user_account_creation_time) <= 30;
