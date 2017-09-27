CREATE TABLE ahemphill.registrations_user as

SELECT 
	DATE(received_at) AS date, 
	user_id,
	event_type, 
	COALESCE(label, 'No associated course') AS course_id, 
FROM 
	experimental_events_run14.event_records 
WHERE 
	event_type = 'edx.bi.user.account.registered';

CREATE TABLE ahemphill.registrations_user_first_login as

SELECT 
	a.date AS registration_date,
	a.user_id,
	a.label AS registered_course,
	MIN(b.date) AS first_login_post_reg
FROM
	ahemphill.registrations_user a
LEFT JOIN
	experimental_events_run14.event_records b
ON 
	a.user_id = b.user_id
AND 
	b.event_type = 'identify'
AND 
	cast(b.date as date) > a.date
GROUP BY 
	1,2,3;

CREATE TABLE ahemphill.registrations_user_first_login_activity as

SELECT 
	a.registration_date,
	a.user_id,
	a.registered_course,
	a.first_login_post_reg,
	COUNT(b.course_id) AS cnt_total_enrolls,
	MIN(c.date) AS first_activity_date,
	COUNT(c.date) AS cnt_days_active,
	SUM(CASE WHEN activity_type IN ('ATTEMPTED_PROBLEM','PLAYED_VIDEO', 'POSTED_FORUM') THEN 1 ELSE 0 END) AS is_engaged
FROM
	ahemphill.registrations_user_first_login a 
LEFT JOIN
	production.d_user_course b
ON
	a.user_id = b.user_id
LEFT JOIN
	production.f_user_activity c
ON
	a.user_id = c.user_id
AND
	c.date >= a.registration_date
GROUP BY 1,2,3,4;

select
registration_date,
user_id,
registered_course,
first_login_post_reg,
COALESCE(DATE(first_login_post_reg), registration_date) AS first_login_post_reg_adj,
DATEDIFF('day',registration_date, date(first_login_post_reg)) AS time_to_first_login,
DATEDIFF('day',registration_date, date(first_activity_date)) AS time_to_first_activity,
case when cnt_days_active >0 then 1 else 0 end as is_active,
case when is_engaged >0 then 1 else 0 end as is_engaged

from ahemphill.registrations_user_first_login_activity