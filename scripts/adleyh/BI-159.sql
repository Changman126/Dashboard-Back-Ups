--create tables to find mobile and web users, first touch for each

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

DROP TABLE IF EXISTS ahemphill.first_non_mobile_touch_anonymous_id;
CREATE TABLE IF NOT EXISTS ahemphill.first_non_mobile_touch_anonymous_id AS
SELECT
	anonymous_id,
	MIN(received_at) AS first_touch
FROM 
	experimental_events_run14.event_records
WHERE 
	app_name IS NULL

GROUP BY 
	anonymous_id;

--combine above two tables, join to identify to only show users that we've mapped w/an LMS id

DROP TABLE IF EXISTS ahemphill.mobile_non_mobile_agg;
CREATE TABLE IF NOT EXISTS ahemphill.mobile_non_mobile_agg AS

SELECT
	a.*,
	b.user_id
FROM
(
SELECT
	anonymous_id,
	app_name,
	os_name,
	'mobile_app' AS type
FROM
	ahemphill.first_mobile_touch_anonymous_id

UNION ALL

SELECT
	anonymous_id,
	NULL as app_name,
	NULL as os_name,
	'web' AS type
FROM
	ahemphill.first_non_mobile_touch_anonymous_id
) a
JOIN
	identify b
ON
	a.anonymous_id = b.anonymous_id;

--categorize users as app only, web only, or both
DROP TABLE IF EXISTS ahemphill.mobile_non_mobile_agg_categorized;
CREATE TABLE IF NOT EXISTS ahemphill.mobile_non_mobile_agg_categorized AS

SELECT
	user_id,
	type
FROM
(
	SELECT
		a.user_id,
		type
	FROM 
		ahemphill.mobile_non_mobile_agg a
	JOIN 
	(
		SELECT 
			user_id,
			count(distinct type) AS multi_platform_users
		FROM 
			ahemphill.mobile_non_mobile_agg
		GROUP BY 
			1
	 	HAVING 
	 		count(distinct type) = 1
	 ) b
	on 
		a.user_id = b.user_id
	GROUP BY
		1,2

	UNION DISTINCT

	SELECT 
		user_id,
		'multi_platform' AS type
	FROM 
		ahemphill.mobile_non_mobile_agg
	GROUP BY 
		1,2
	HAVING 
		COUNT(distinct type) > 1	
) a


--count em up

SELECT
	type,
	COUNT(1) AS cnt_users
FROM
(
	SELECT
		a.user_id,
		type
	FROM 
		ahemphill.mobile_non_mobile_agg a
	JOIN 
	(
		SELECT 
			user_id,
			count(distinct type) AS multi_platform_users
		FROM 
			ahemphill.mobile_non_mobile_agg
		GROUP BY 
			1
	 	HAVING 
	 		count(distinct type) = 1
	 ) b
	on 
		a.user_id = b.user_id
	GROUP BY
		1,2

	UNION DISTINCT

	SELECT 
		user_id,
		'multi_platform' AS type
	FROM 
		ahemphill.mobile_non_mobile_agg
	GROUP BY 
		1,2
	HAVING 
		COUNT(distinct type) > 1	
) a
GROUP BY
	type

--what % of users are on both app and web

SELECT
	multi_platform_users,
	COUNT(1) as cnt_users
FROM
(
	SELECT 
		user_id,
		count(distinct type) AS multi_platform_users
	FROM 
		ahemphill.mobile_non_mobile_agg
	GROUP BY 
		1
) a
GROUP BY
	1

--what % of single platform users are app vs web

SELECT
	type,
	count(distinct a.user_id) as cnt_users
FROM 
	ahemphill.mobile_non_mobile_agg a
JOIN 
(
	SELECT 
		user_id,
		count(distinct type) AS multi_platform_users
	FROM 
		ahemphill.mobile_non_mobile_agg
	GROUP BY 
		1
 	HAVING 
 		count(distinct type) = 1
 ) b
on 
	a.user_id = b.user_id
GROUP BY
	1

--what % of app users are iOS vs Android

SELECT 
	os_name, 
	count(distinct user_id) 
FROM 
	ahemphill.mobile_non_mobile_agg
WHERE 
	type = 'mobile_app'
GROUP BY 
	1

--what number of enrolls and registrations come from the app

SELECT
	cnt_enrolls_mobile,
	cnt_registrations_mobile,
	SUM(b.cnt_enrolls) AS cnt_enrolls_total,
	SUM(c.cnt_registrations) AS cnt_registrations_total
FROM
(
	SELECT
	    DATE(MIN(received_at)) AS start_date,
	    SUM(CASE WHEN event_type = 'Enroll Course Clicked' THEN 1 ELSE 0 END) AS cnt_enrolls_mobile,
	    SUM(CASE WHEN event_type = 'Register' THEN 1 ELSE 0 END) AS cnt_registrations_mobile
	FROM 
		experimental_events_run14.event_records a
	WHERE
		a.app_name = 'edX'
	AND 
		a.event_type IN ('Enroll Course Clicked', 'Register')
) a
JOIN
(
	SELECT
		DATE(first_enrollment_time) AS enroll_date,
		COUNT(1) AS cnt_enrolls
	FROM
		production.d_user_course
	GROUP BY
		1
) b
ON
	b.enroll_date >= a.start_date
JOIN
(
	SELECT
		DATE(user_account_creation_time) AS registration_date,
		COUNT(1) AS cnt_registrations
	FROM
		production.d_user
	GROUP BY
		1
) c
ON
	c.registration_date >= a.start_date
AND
	c.registration_date = b.enroll_date
GROUP BY
	1,2

--per course, check user categorization to see if certain courses are taken more frequently by mobile, web, or mixed users

DROP TABLE IF EXISTS ahemphill.mobile_non_mobile_agg_categorized_summary;
CREATE TABLE IF NOT EXISTS ahemphill.mobile_non_mobile_agg_categorized_summary AS
SELECT
        a.course_id,
        course_name,
        course_partner,
        course_subject,
        program_title,
        program_type,
        type,
        a.cnt_users
FROM 
(
SELECT 
	a.course_id,
	c.course_name,
	c.course_partner,
	c.course_subject,
	d.program_title,
	d.program_type,
	type,
	count(1) AS cnt_users
FROM 
	production.d_user_course a 
JOIN 
	ahemphill.mobile_non_mobile_agg_categorized b
ON 
	a.user_id = b.user_id
JOIN
	course_master c
ON
	a.course_id = c.course_id
LEFT JOIN
	production.d_program_course d
ON
	a.course_id = d.course_id
GROUP BY 
	1,2,3,4,5,6,7
) a
JOIN
(
SELECT 
	a.course_id,
	count(1) AS cnt_users
FROM 
	production.d_user_course a 
JOIN 
	ahemphill.mobile_non_mobile_agg_categorized b
ON 
	a.user_id = b.user_id
GROUP BY
1
having count(1) > 1000

) b 
on a.course_id = b.course_id;
