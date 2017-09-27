CREATE TABLE ahemphill.engagement_activity_test AS

SELECT
	CURRENT_DATE() AS date,
	a.user_id,
	SUM(CASE WHEN b.date >= CURRENT_DATE() - 7 THEN 1 ELSE 0 END) AS active_7d,
	SUM(CASE WHEN b.date >= CURRENT_DATE() - 14 THEN 1 ELSE 0 END) AS active_14d,
	SUM(CASE WHEN b.date >= CURRENT_DATE() - 30 THEN 1 ELSE 0 END) AS active_30d,
	SUM(CASE WHEN b.date >= CURRENT_DATE() - 7 AND b.activity_type IN ('ATTEMPTED_PROBLEM', 'PLAYED_VIDEO') THEN 1 ELSE 0 END) AS engaged_7d,
	SUM(CASE WHEN b.date >= CURRENT_DATE() - 14 AND b.activity_type IN ('ATTEMPTED_PROBLEM', 'PLAYED_VIDEO') THEN 1 ELSE 0 END) AS engaged_14d,
	SUM(CASE WHEN b.date >= CURRENT_DATE() - 30 AND b.activity_type IN ('ATTEMPTED_PROBLEM', 'PLAYED_VIDEO') THEN 1 ELSE 0 END) AS engaged_30d

 FROM 
 (
	SELECT 
		DISTINCT a.user_id, 
		a.course_id
	FROM 
		d_user_course a 
	JOIN 
		d_course b 
	ON 
		a.course_id = b.course_id 
	AND 
		a.last_unenrollment_time is null
	AND 
		b.availability = 'Current'
	AND 
		datediff('day',first_enrollment_time, current_date()) <= 90
	LEFT JOIN 
		d_user_course_certificate c
	ON 
		a.user_id = c.user_id
	AND 
		a.course_id = c.course_id
	WHERE 
		has_passed = 0 
		OR has_passed IS NULL
) a
LEFT JOIN 
	f_user_activity b
ON 
	a.user_id = b.user_id
AND 
	a.course_id = b.course_id
GROUP BY
	1

	SELECT 
current_date(),
count(1),
SUM(CASE WHEN active_7d > 0 THEN 1 ELSE 0 END) * 100.0/count(1) AS active_rate_7d,
SUM(CASE WHEN active_14d > 0 THEN 1 ELSE 0 END) * 100.0/count(1) AS active_rate_14d,
SUM(CASE WHEN active_30d > 0 THEN 1 ELSE 0 END) * 100.0/count(1) AS active_rate_30d,
SUM(CASE WHEN engaged_7d > 0 THEN 1 ELSE 0 END) * 100.0/count(1) AS engagement_rate_7d,
SUM(CASE WHEN engaged_14d > 0 THEN 1 ELSE 0 END) * 100.0/count(1) AS engagement_rate_14d,
SUM(CASE WHEN engaged_30d > 0 THEN 1 ELSE 0 END) * 100.0/count(1) AS engagement_rate_30d

FROM ahemphill.engagement_activity_test 