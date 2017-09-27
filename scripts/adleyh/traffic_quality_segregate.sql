SELECT
--a.user_id,
	user_last_location_country_code,
	SUM(case when cnt_enrolls IS NOT NULL OR cnt_enrolls >0 THEN 1 ELSE 0 END) AS cnt_enrolled_users,
	SUM(case when cnt_verifs>0 THEN 1 ELSE 0 END) AS cnt_verified_users,
	count(1) AS cnt_registered_users,
	SUM(case when cnt_enrolls IS NOT NULL THEN 1 ELSE 0 END)*100.0/count(1) AS pct_enrolled_users,
	SUM(case when cnt_verifs>0  THEN 1 ELSE 0 END)*100.0/count(1) AS pct_verified_users,
	count(c.user_id) AS cnt_engaged_users,
	count(c.user_id)*100.0/count(1) as pct_engaged_users
FROM 
	production.d_user a 
LEFT JOIN
(
	SELECT
		user_id,
		count(1) as cnt_enrolls,
		count(first_verified_enrollment_time) AS cnt_verifs
	FROM 
		production.d_user_course
	GROUP BY 
		user_id
) b
ON 
	a.user_id = b.user_id
LEFT JOIN
(
	SELECT
		user_id
	FROM 
		production.f_user_activity
	WHERE 
		activity_type != 'ACTIVE'
	GROUP BY
		user_id
) c
ON 
	a.user_id = c.user_id
WHERE 
	user_last_location_country_code IN ('US','IN')
AND 
	user_account_creation_time >= '2016-07-01'
GROUP BY
	user_last_location_country_code