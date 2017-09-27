DROP TABLE IF EXISTS ahemphill.course_enroll;
CREATE TABLE ahemphill.course_activity AS
SELECT 
	a.*
FROM
(
	SELECT
		a.*,
		b.subject_title,
		c.start_time,
		c.catalog_course_title,
		DATEDIFF('day', c.start_time, CASE WHEN c.end_time <= '2016-11-06' THEN c.end_time ELSE '2016-11-06' END) AS course_days_from_start,
		row_number() OVER (partition by a.user_id, a.course_id order by random()) AS rank
	FROM
		d_user_course a
	LEFT JOIN 
		d_course_subjects b
	ON 
		a.course_id = b.course_id
	LEFT JOIN
		d_course c
	ON 
		a.course_id = c.course_id
	WHERE 
		c.start_time > '2016-01-01'
		AND b.subject_title IS NOT NULL
) a
WHERE 
	rank = 1;

DROP TABLE IF EXISTS ahemphill.user_activity_agg;
CREATE TABLE ahemphill.user_activity_agg AS

SELECT
	user_id,
	course_id,
	COUNT(DISTINCT date) AS cnt_days_active
FROM 
	f_user_activity
WHERE 
	date > '2016-01-01'
GROUP BY 1,2;






DROP TABLE IF EXISTS ahemphill.activity_agg_subject;
CREATE TABLE ahemphill.activity_agg_subject AS

SELECT
	subject_title,
	median_pct_days_active,
	SUM(CASE WHEN pct_days_active = 0 THEN 1 ELSE 0 END) AS cnt_users_zero_activity,
	SUM(CASE WHEN pct_days_active = 0 THEN 1 ELSE 0 END)*100.0/count(1) AS pct_users_zero_activity
FROM
(
	SELECT
		subject_title,
		pct_days_active,
		MEDIAN(pct_days_active) OVER (partition by subject_title) AS median_pct_days_active
	FROM
	(
		SELECT 
			a.*,
			b.cnt_days_active, 
			(CASE WHEN b.cnt_days_active IS NOT NULL THEN b.cnt_days_active ELSE 0 END)*100.0/a.course_days_from_start AS pct_days_active
		FROM
			ahemphill.course_activity a
		LEFT JOIN 
			ahemphill.user_activity_agg b
		ON 
			a.user_id = b.user_id
			AND a.course_id = b.course_id
		WHERE 
			a.course_days_from_start > 0
	) a
) b
GROUP BY 1,2;

DROP TABLE IF EXISTS ahemphill.activity_agg_course;
CREATE TABLE ahemphill.activity_agg_course AS

SELECT
	course_id,
	median_pct_days_active,
	SUM(CASE WHEN pct_days_active = 0 THEN 1 ELSE 0 END) AS cnt_users_zero_activity,
	SUM(CASE WHEN pct_days_active = 0 THEN 1 ELSE 0 END)*100.0/count(1) AS pct_users_zero_activity
FROM
(
	SELECT
		course_id,
		pct_days_active,
		MEDIAN(pct_days_active) OVER (partition by course_id) AS median_pct_days_active
	FROM
	(
		SELECT 
			a.*,
			b.cnt_days_active, 
			(CASE WHEN b.cnt_days_active IS NOT NULL THEN b.cnt_days_active ELSE 0 END)*100.0/a.course_days_from_start AS pct_days_active
		FROM
			ahemphill.course_activity a
		LEFT JOIN 
			ahemphill.user_activity_agg b
		ON 
			a.user_id = b.user_id
			AND a.course_id = b.course_id
		WHERE 
			a.course_days_from_start > 0
	) a
) b
GROUP BY 1,2;


DROP TABLE IF EXISTS ahemphill.zero_activity_course;
CREATE TABLE ahemphill.zero_activity_course AS

	SELECT
	course_id,
	catalog_course_title,
	SUM(CASE WHEN cnt_days_active = 0 THEN 1 ELSE 0 END) AS cnt_users_zero_activity,
	SUM(CASE WHEN cnt_days_active = 0 THEN 1 ELSE 0 END)*100.0/count(1) AS pct_users_zero_activity,
	count(1) AS cnt_users
	FROM
	(
		SELECT 
			a.*,
			(CASE WHEN b.cnt_days_active IS NOT NULL THEN b.cnt_days_active ELSE 0 END) AS cnt_days_active
		FROM
			ahemphill.course_activity a
		LEFT JOIN 
			ahemphill.user_activity_agg b
		ON 
			a.user_id = b.user_id
			AND a.course_id = b.course_id
		WHERE 
			a.course_days_from_start > 0
	) a

GROUP BY 1,2;


----

DROP TABLE IF EXISTS ahemphill.user_activity_agg;
CREATE TABLE ahemphill.user_activity_agg AS

SELECT
	a.user_id,
	a.course_id,
	date(a.first_enrollment_time) AS user_enrollment_date,
	b.date AS activity_date,
	c.start_time AS course_start_date,
	CASE WHEN date(a.first_enrollment_time) < date(c.start_time) 
	THEN date(c.start_time) ELSE date(a.first_enrollment_time) END AS first_eligible_activity_date,
	c.pacing_type,
	c.level_type,
	c.org_id,
	COUNT(b.date) AS cnt_activity
FROM 
	d_user_course a
LEFT JOIN
	f_user_activity b
ON
	a.user_id = b.user_id
	AND a.course_id = b.course_id
LEFT JOIN
	d_course c
ON
	a.course_id = c.course_id
WHERE 
	c.end_time BETWEEN '2016-01-01' AND '2016-11-01'
GROUP BY 1,2,3,4,5,6,7,8,9;

DROP TABLE IF EXISTS ahemphill.user_activity_over_time;
CREATE TABLE ahemphill.user_activity_over_time AS

SELECT
	user_id,
	course_id,
	user_enrollment_date,
	activity_date,
	course_start_date,
	first_eligible_activity_date,
	pacing_type,
	level_type,
	org_id,
	count(distinct activity_date) AS days_active,
	MAX(active_7d) AS active_7d,
	MAX(active_14d) AS active_14d,
	MAX(active_30d) AS active_30d,
	MAX(active_60d) AS active_60d,
	MAX(active_90d) AS active_90d,
	MAX(active_180d) AS active_180d,
	MAX(active_ever) AS active_ever

FROM
(
	SELECT 
		*,
		DATEDIFF('day',date(first_eligible_activity_date),activity_date) AS activity_days_from_course_start,
		CASE WHEN DATEDIFF('day',date(first_eligible_activity_date),activity_date) BETWEEN 0 AND 7 THEN 1 ELSE 0 END AS active_7d,
		CASE WHEN DATEDIFF('day',date(first_eligible_activity_date),activity_date) BETWEEN 7 AND 14 THEN 1 ELSE 0 END AS active_14d,
		CASE WHEN DATEDIFF('day',date(first_eligible_activity_date),activity_date) BETWEEN 14 AND 30 THEN 1 ELSE 0 END AS active_30d,
		CASE WHEN DATEDIFF('day',date(first_eligible_activity_date),activity_date) BETWEEN 30 AND 60 THEN 1 ELSE 0 END AS active_60d,
		CASE WHEN DATEDIFF('day',date(first_eligible_activity_date),activity_date) BETWEEN 60 AND 90 THEN 1 ELSE 0 END AS active_90d,
		CASE WHEN DATEDIFF('day',date(first_eligible_activity_date),activity_date) BETWEEN 90 AND 180 THEN 1 ELSE 0 END AS active_180d,
		CASE WHEN DATEDIFF('day',date(first_eligible_activity_date),activity_date) BETWEEN 0 AND 365 THEN 1 ELSE 0 END AS active_ever
	FROM 
		ahemphill.user_activity_agg
) a
GROUP BY 1,2,3,4,5,6,7,8,9;

DROP TABLE IF EXISTS ahemphill.user_activity_over_time_summary;
CREATE TABLE ahemphill.user_activity_over_time_summary AS

SELECT 
	course_id,
	COUNT(1) AS cnt_enrolls,
	SUM(active_ever) AS cnt_ever_active,
	SUM(active_7d) AS cnt_7d_active,
	SUM(active_14d) AS cnt_14d_active,
	SUM(active_30d) AS cnt_30d_active,
	SUM(active_60d) AS cnt_60d_active,
	SUM(active_90d) AS cnt_90d_active,
	SUM(active_180d) AS cnt_180d_active
FROM 
	ahemphill.user_activity_over_time
GROUP BY
	course_id;











