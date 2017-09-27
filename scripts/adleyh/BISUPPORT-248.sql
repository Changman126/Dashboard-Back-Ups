DROP TABLE IF EXISTS ahemphill.first_mobile_touch_anonymous_id;
CREATE TABLE IF NOT EXISTS ahemphill.first_mobile_touch_anonymous_id AS
SELECT
	anonymous_id,
	app_name,
	os_name,
	MIN(received_at) AS first_touch
FROM 
	experimental_events_run14.event_records
WHERE 
	app_name = 'edX'
AND 
	os_name IN ('Android','iOS')
GROUP BY 
	anonymous_id,
	app_name,
	os_name;

--num downloads per platform

SELECT 
	os_name,
	COUNT(1) AS cnt_downloads
FROM 
	ahemphill.first_mobile_touch_anonymous_id 
WHERE
	first_touch BETWEEN '2017-05-24' AND '2017-06-01'
GROUP BY
	os_name;


--num downloads per platform

SELECT 
	os_name,
	COUNT(1) AS cnt_downloads,
	COUNT(c.user_id) AS returning_users
FROM 
	ahemphill.first_mobile_touch_anonymous_id a
LEFT OUTER JOIN
	business_intelligence.identify b
ON
	a.anonymous_id = b.anonymous_id
LEFT OUTER JOIN
	production.d_user c
ON
	b.user_id = c.user_id
AND
	c.user_account_creation_time <= CAST(first_touch AS TIMESTAMP)
WHERE
	first_touch BETWEEN '2017-05-24' AND '2017-06-01'
GROUP BY
	os_name;
