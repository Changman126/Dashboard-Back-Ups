CREATE TABLE ahemphill.activity_engagement_rate_course_level AS

SELECT
	course_id,
	SUM(is_active) *100.0/COUNT(1) AS active_rate,
	SUM(is_active) as cnt_active,
	SUM(is_engaged) *100.0/COUNT(1) AS engaged_rate,
	SUM(is_engaged) as cnt_engaged,
	COUNT(1) AS cnt_users
from
(
	SELECT
		a.user_id,
		a.course_id,
		MAX(CASE WHEN b.user_id IS NOT NULL THEN 1 ELSE 0 END) AS is_active,
		MAX(CASE WHEN c.user_id IS NOT NULL THEN 1 ELSE 0 END) AS is_engaged
	FROM
	(
		SELECT
			a.user_id,
			a.course_id,
			CASE 
				WHEN a.first_enrollment_time >= b.start_time THEN a.first_enrollment_time
				ELSE b.start_time
			END AS content_availability_date,
			a.first_enrollment_time,
			b.start_time
		FROM 
			production.d_user_course a
		JOIN 
			production.d_course b
		ON 
			a.course_id = b.course_id
		WHERE
			CASE 
				WHEN a.first_enrollment_time >= b.start_time THEN a.first_enrollment_time
				ELSE b.start_time
			END >= CURRENT_DATE()-30
	) a
	LEFT JOIN
	(
		SELECT
			user_id,
			course_id,
			MAX(date) AS date
		FROM 
			production.f_user_activity
		WHERE 
			date >= CURRENT_DATE()-30
		GROUP BY 
			user_id,
			course_id

	) b
	ON 
		a.user_id = b.user_id
	AND
		a.course_id = b.course_id
	AND
		b.date >= DATE(a.content_availability_date)
	LEFT JOIN
	(
		SELECT
			user_id,
			course_id,
			MAX(date) AS date
		FROM 
			production.f_user_activity
		WHERE 
			date >= CURRENT_DATE()-30
		AND 
			activity_type IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM', 
				'POSTED_FORUM') 
		GROUP BY 
			user_id,
			course_id
	) c
	ON 
		a.user_id = c.user_id
	AND
		a.course_id = c.course_id
	AND
		c.date >= DATE(a.content_availability_date)
	GROUP BY
		a.user_id,
		a.course_id
) a
GROUP BY
	course_id;

CREATE TABLE ahemphill.activity_engagement_rate_user_level AS

SELECT
	SUM(is_active) *100.0/COUNT(1) AS active_rate,
	SUM(is_engaged) *100.0/COUNT(1) AS engaged_rate,
	COUNT(1) AS cnt_users
from
(
	SELECT
		a.user_id,
		MAX(CASE WHEN b.user_id IS NOT NULL THEN 1 ELSE 0 END) AS is_active,
		MAX(CASE WHEN c.user_id IS NOT NULL THEN 1 ELSE 0 END) AS is_engaged
	FROM
	(
		SELECT
			a.user_id,
			a.course_id,
			CASE 
				WHEN a.first_enrollment_time >= b.start_time THEN a.first_enrollment_time
				ELSE b.start_time
			END AS content_availability_date,
			a.first_enrollment_time,
			b.start_time
		FROM 
			production.d_user_course a
		JOIN 
			production.d_course b
		ON 
			a.course_id = b.course_id
		WHERE
			CASE 
				WHEN a.first_enrollment_time >= b.start_time THEN a.first_enrollment_time
				ELSE b.start_time
			END >= DATE('2017-03-01')-30
	) a
	LEFT JOIN
	(
		SELECT
			user_id,
			course_id,
			MAX(date) AS date
		FROM 
			production.f_user_activity
		WHERE 
			date >= CURRENT_DATE()-30
		GROUP BY 
			user_id,
			course_id

	) b
	ON 
		a.user_id = b.user_id
	AND
		a.course_id = b.course_id
	AND
		b.date >= DATE(a.content_availability_date)
	LEFT JOIN
	(
		SELECT
			user_id,
			course_id,
			MAX(date) AS date
		FROM 
			production.f_user_activity
		WHERE 
			date >= DATE('2017-03-01')-30
		AND 
			activity_type IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM', 
				'POSTED_FORUM') 
		GROUP BY 
			user_id,
			course_id
	) c
	ON 
		a.user_id = c.user_id
	AND
		a.course_id = c.course_id
	AND
		c.date >= DATE(a.content_availability_date)
	GROUP BY
		a.user_id
) a;