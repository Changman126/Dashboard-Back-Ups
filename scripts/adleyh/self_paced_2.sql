DROP TABLE IF EXISTS ahemphill.retention_dropoff_base;
CREATE TABLE ahemphill.retention_dropoff_base AS

SELECT * 
FROM 
(
	SELECT 
		user_id,
		catalog_course,
		a.course_id,
		case when first_enrollment_time>start_time then first_enrollment_time else start_time end AS content_availability_date,
		pacing_type
	FROM 
		d_user_course a 
	JOIN 
		d_course b
	ON 
		a.course_id = b.course_id
) a 
WHERE 
	content_availability_date BETWEEN '2016-03-07' AND '2017-02-01';

DROP TABLE if exists ahemphill.retention_dropoff_eligible_courses;
CREATE TABLE ahemphill.retention_dropoff_eligible_courses AS

SELECT
	a.user_id,
	a.course_id,
	a.content_availability_date,
	a.catalog_course,
	a.pacing_type
FROM
	ahemphill.retention_dropoff_base a
JOIN
(
		SELECT
			catalog_course,
			course_id,
			pacing_type,
			count(1) AS cnt_enrolls
		FROM 
			ahemphill.retention_dropoff_base
		GROUP BY 
			1,2,3
		HAVING
		      count(1) > 5000
) b
ON a.course_id = b.course_id
WHERE a.catalog_course IN
(
	SELECT
		a.catalog_course
		
	FROM
	(
		SELECT
			catalog_course,
			course_id,
			pacing_type,
			count(1) AS cnt_enrolls
		FROM 
			ahemphill.retention_dropoff_base
		GROUP BY 
			1,2,3
		HAVING
		      count(1) > 5000
	) a
	JOIN
	(
		SELECT
			catalog_course,
			COUNT(distinct pacing_type) AS cnt_pacing
		FROM 
			ahemphill.retention_dropoff_base
		GROUP BY 
			1
		HAVING 
			COUNT(DISTINCT pacing_type) > 1
	) b
	ON a.catalog_course = b.catalog_course
	GROUP BY 
		1
	HAVING 
		count(distinct pacing_type) > 1
);

SELECT
	catalog_course,
	course_id,
	pacing_type,
	count(1) as cnt_enrolls,
	SUM(engaged_7d) AS sum_engaged_7d,
	SUM(engaged_14d) AS sum_engaged_14d,
	SUM(engaged_21d) AS sum_engaged_21d,
	SUM(CASE WHEN engaged_7d = 1 THEN engaged_14d ELSE 0 END) * 100.0/
	SUM(engaged_7d) AS retention_14d,
	SUM(CASE WHEN engaged_7d = 1 AND engaged_14d = 1 THEN engaged_21d ELSE 0 END) * 100.0/
	SUM(CASE WHEN engaged_7d = 1 THEN 1 ELSE 0 END) AS retention_21d

FROM
(
	SELECT
	a.user_id,
	a.catalog_course,
	a.course_id,
	a.pacing_type,
	MAX(CASE WHEN DATEDIFF('day', content_availability_date, c.date) between 0 and 7 
		AND activity_type IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM') THEN 1 ELSE 0 END) AS engaged_7d,
	MAX(CASE WHEN DATEDIFF('day', content_availability_date, c.date) between 8 and 14  
		AND activity_type IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM') THEN 1 ELSE 0 END) AS engaged_14d,
	MAX(CASE WHEN DATEDIFF('day', content_availability_date, c.date) between 15 and 21  
		AND activity_type IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM') THEN 1 ELSE 0 END) AS engaged_21d

	FROM 
		ahemphill.retention_dropoff_eligible_courses a
	LEFT JOIN 
		f_user_activity c
	ON 
		a.course_id = c.course_id
	AND 
		a.user_id = c.user_id
	GROUP BY 
		1,2,3,4
) a
GROUP BY 
	1,2,3
