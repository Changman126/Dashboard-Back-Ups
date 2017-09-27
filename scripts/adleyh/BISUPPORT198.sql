CREATE TABLE ahemphill.bisupport198 (user_email varchar(555), date_sent DATE, course_id VARCHAR(555);

COPY ahemphill.bisupport198 FROM LOCAL '/Users/adleyhemphill/Documents/bisupport198.csv' WITH DELIMITER ',';

DROP TABLE ahemphill.bisupport198_user_grouping;
CREATE TABLE ahemphill.bisupport198_user_grouping AS
SELECT
	user_id,
	course_id,
	date_email_sent,
	CASE
		WHEN DATEDIFF('day', latest_engagement_prior_email,date_email_sent) BETWEEN 0 AND 6 THEN 'within_1_week'
		WHEN DATEDIFF('day', latest_engagement_prior_email,date_email_sent) BETWEEN 7 AND 29 THEN '1_week_to_1_month'
		WHEN DATEDIFF('day', latest_engagement_prior_email,date_email_sent) > 29 THEN '>1_month'
		ELSE 'never_active'
	END AS activity_group
FROM
(
	SELECT 
		b.user_id,
		a.course_id,
		a.date_sent AS date_email_sent,
		MAX(c.date) AS latest_engagement_prior_email
	FROM 
		ahemphill.bisupport198 a 
	JOIN 
		production.d_user b
	ON 
		a.user_email = b.user_email
	LEFT JOIN 
		production.f_user_activity c
	ON 
		b.user_id = c.user_id
	AND 
		a.course_id = c.course_id
	AND 
		c.date < a.date_sent
	AND
		c.activity_type != 'ACTIVE'
	GROUP BY
		1,2,3
) a;


SELECT
	course_id,
	activity_group,
	COUNT(1) AS cnt_in_group,
	COUNT(first_engagement_post_email) AS cnt_engagement_after_email,
	COUNT(first_verified_enrollment_time) AS cnt_verifs_after_email
FROM
(
	SELECT
		a.user_id,
		a.course_id,
		a.activity_group,
		c.first_verified_enrollment_time,
		MIN(b.date) AS first_engagement_post_email
	FROM
		ahemphill.bisupport198_user_grouping a
	LEFT JOIN 
		production.f_user_activity b
	ON 
		a.user_id = b.user_id
	AND 
		a.course_id = b.course_id
	AND 
		b.date >= a.date_email_sent
	AND
		b.activity_type != 'ACTIVE'
	LEFT JOIN
		production.d_user_course c
	ON 
		a.user_id = c.user_id
	AND 
		a.course_id = c.course_id
	AND 
		DATE(c.first_verified_enrollment_time) >= a.date_email_sent
	GROUP BY
		1,2,3,4
) a
GROUP BY 1,2