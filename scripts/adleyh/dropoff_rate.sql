DROP TABLE IF EXISTS ahemphill.user_course_content_availability;
CREATE TABLE IF NOT EXISTS ahemphill.user_course_content_availability AS
SELECT
	user_id,
	a.course_id,
	date(b.start_time) AS course_start_time,
	GREATEST(date(a.first_enrollment_time), date(b.start_time)) AS content_availability_date
FROM 
	d_user_course a
JOIN 
	d_course b
ON a.course_id = b.course_id;

DROP TABLE IF EXISTS ahemphill.user_course_content_availability_activity;
CREATE TABLE IF NOT EXISTS ahemphill.user_course_content_availability_activity AS

SELECT
	a.user_id,
	a.course_id,
	a.content_availability_date,
	a.course_start_time,
	SUM(b.number_of_activities) AS cnt_activities,
	SUM(CASE WHEN DATEDIFF('day', a.content_availability_date, b.date) <=7 THEN 1 ELSE 0 END) AS cnt_consumed_content_7d,
	SUM(CASE WHEN DATEDIFF('day', a.content_availability_date, b.date) <=14 THEN 1 ELSE 0 END) AS cnt_consumed_content_14d,
	SUM(CASE WHEN DATEDIFF('day', a.content_availability_date, b.date) <=21 THEN 1 ELSE 0 END) AS cnt_consumed_content_21d,
	SUM(CASE WHEN DATEDIFF('day', a.content_availability_date, b.date) <=28 THEN 1 ELSE 0 END) AS cnt_consumed_content_28d
FROM
	ahemphill.user_course_content_availability a
LEFT JOIN
	f_user_activity b
ON a.user_id = b.user_id
AND a.course_id = b.course_id
AND b.date >= a.content_availability_date
AND b.activity_type IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM')
GROUP BY
	a.user_id,
	a.course_id,
	a.content_availability_date,
	a.course_start_time;

DROP TABLE IF EXISTS ahemphill.user_course_content_availability_summary;
CREATE TABLE IF NOT EXISTS ahemphill.user_course_content_availability_summary AS

SELECT
	a.course_id,
	COUNT(1) AS cnt_enrolls,
	SUM(CASE WHEN cnt_activities > 0 THEN 1 ELSE 0 END) AS cnt_consumed_content_ever,
	SUM(CASE WHEN cnt_consumed_content_7d > 0 THEN 1 ELSE 0 END) AS cnt_consumed_content_7d,
	SUM(CASE WHEN cnt_consumed_content_14d > 0 AND cnt_consumed_content_14d > cnt_consumed_content_7d THEN 1 ELSE 0 END) AS cnt_consumed_content_14d,
	SUM(CASE WHEN cnt_consumed_content_21d > 0 AND cnt_consumed_content_21d > cnt_consumed_content_14d THEN 1 ELSE 0 END) AS cnt_consumed_content_21d,
	SUM(CASE WHEN cnt_consumed_content_28d > 0 AND cnt_consumed_content_28d > cnt_consumed_content_21d THEN 1 ELSE 0 END) AS cnt_consumed_content_28d,
	SUM(CASE WHEN cnt_consumed_content_7d > 0 THEN 1 ELSE 0 END)*100.0/SUM(CASE WHEN cnt_activities > 0 THEN 1 ELSE 0 END) AS pct_consumed_content_7d,
	SUM(CASE WHEN cnt_activities > 0 THEN 1 ELSE 0 END) * 100.0/COUNT(1) AS pct_engaged_ever,
	SUM(CASE WHEN cnt_consumed_content_7d > 0 THEN 1 ELSE 0 END) * 100.0/COUNT(1) AS pct_engaged_7d,
	SUM(CASE WHEN cnt_consumed_content_14d > 0 AND cnt_consumed_content_14d > cnt_consumed_content_7d THEN 1 ELSE 0 END) * 100.0/COUNT(1) AS pct_engaged_14d,
	SUM(CASE WHEN cnt_consumed_content_21d > 0 AND cnt_consumed_content_21d > cnt_consumed_content_14d THEN 1 ELSE 0 END) * 100.0/COUNT(1) AS pct_engaged_21d,
	SUM(CASE WHEN cnt_consumed_content_28d > 0 AND cnt_consumed_content_28d > cnt_consumed_content_21d THEN 1 ELSE 0 END) * 100.0/COUNT(1) AS pct_engaged_28d
FROM
	ahemphill.user_course_content_availability_activity a
WHERE
	a.course_start_time > '2016-01-01'
GROUP BY
	a.course_id;