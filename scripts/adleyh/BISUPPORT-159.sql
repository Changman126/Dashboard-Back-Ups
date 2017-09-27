SELECT
	d_user.user_id,
	country.country_name,
	CASE
		WHEN last_day_active < 14 THEN 'active'
		WHEN last_day_active BETWEEN 14 AND 180 THEN 'active_0_to_6_months'
		WHEN last_day_active >= 180 THEN 'active_greater_6_months'
		ELSE 'not_active'
	END AS activity_status,
	 last_day_active
FROM
	production.d_user d_user
JOIN
	production.d_country country
ON
	country.country_name IN
	(
	'Argentina',
	'Chile',
	'Colombia',
	'Ecuador',
	'Spain',
	'Mexico',
	'Peru',
	'Venezuela',
	'United States'
	)
AND
	d_user.user_last_location_country_code = country.user_last_location_country_code
AND
	d_user.user_account_creation_time >= '2016-04-05'
LEFT JOIN
(
	SELECT
		user_id,
		MIN(DATEDIFF('day', date, CURRENT_DATE())) AS last_day_active
	FROM
		production.f_user_activity
	GROUP BY
		user_id
) activity
ON
	d_user.user_id = activity.user_id;


SELECT
country_name,
activity_status,
count(distinct user_id) AS cnt_users
FROM
(
SELECT
	d_user.user_id,
	country.country_name,
	CASE
		WHEN last_day_active < 14 THEN 'active'
		WHEN last_day_active BETWEEN 14 AND 180 THEN 'active_0_to_6_months'
		WHEN last_day_active >= 180 THEN 'active_greater_6_months'
		ELSE 'not_active'
	END AS activity_status,
	 last_day_active
FROM
	production.d_user d_user
JOIN
	production.d_country country
ON
	country.country_name IN
	(
	'Argentina',
	'Chile',
	'Colombia',
	'Ecuador',
	'Spain',
	'Mexico',
	'Peru',
	'Venezuela',
	'United States'
	)
AND
	d_user.user_last_location_country_code = country.user_last_location_country_code
AND
	d_user.user_account_creation_time >= '2016-04-05'
LEFT JOIN
(
	SELECT
		user_id,
		MIN(DATEDIFF('day', date, CURRENT_DATE())) AS last_day_active
	FROM
		production.f_user_activity
	GROUP BY
		user_id
) activity
ON
d_user.user_id = activity.user_id
) a
GROUP BY 1,2