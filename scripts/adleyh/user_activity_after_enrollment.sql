DROP TABLE IF EXISTS ahemphill.user_activity_after_enrollment;
CREATE TABLE IF NOT EXISTS ahemphill.user_activity_after_enrollment AS

SELECT
	a.course_id,
	d.user_last_location_country_code,
	COUNT(distinct a.user_id) AS cnt_activities
FROM
	f_user_activity a
JOIN d_user_course b
ON a.user_id = b.user_id
JOIN d_course c
ON a.course_id = c.course_id
AND c.availability = 'Current'
JOIN d_user d
ON a.user_id = d.user_id
WHERE 
	datediff('day', date, date(first_enrollment_time)) >= 1
GROUP BY
	1,2

DROP TABLE IF EXISTS ahemphill.user_activity_after_enrollment_summary;
CREATE TABLE IF NOT EXISTS ahemphill.user_activity_after_enrollment_summary AS

SELECT
	a.course_id,
	b.user_last_location_country_code,
	COUNT(1) AS cnt_enrolls,
	b.cnt_activities*100.0/COUNT(1) AS pct_active,
	b.cnt_activities AS cnt_users_active
FROM
	d_user_course a
JOIN
	ahemphill.user_activity_after_enrollment b
ON a.course_id = b.course_id
JOIN d_user c
ON a.user_id = c.user_id
AND b.user_last_location_country_code = c.user_last_location_country_code
GROUP BY 
	1, 
	b.cnt_activities, 
	b.user_last_location_country_code