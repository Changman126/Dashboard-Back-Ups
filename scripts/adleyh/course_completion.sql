DROP TABLE IF EXISTS ahemphill.fy18_course_completion_baseline;
CREATE TABLE IF NOT EXISTS ahemphill.fy18_course_completion_baseline AS

SELECT
	cal.date,
	a.course_id,
	b.weekly_engagement_level AS week_1_engagement_level,
	CASE 
		WHEN (c.letter_grade = '' OR c.letter_grade IS NULL) THEN 0
		ELSE 1 
	END AS has_passed,
	COUNT(1) AS cnt_users
FROM 
	calendar cal
JOIN
	user_content_availability_date a
ON
	content_availability_date = DATE(cal.date) - 120
AND
	cal.date BETWEEN '2016-07-01' AND CURRENT_DATE()
JOIN 
	user_activity_engagement_weekly b 
ON 
	a.user_id = b.user_id
AND 
	a.course_id = b.course_id
AND 
	b.week = 'week_1'
AND 
	b.weekly_engagement_level != 'no_engagement'
LEFT JOIN 
	lms_read_replica.grades_persistentcoursegrade c
ON 
	a.user_id = c.user_id
AND 
	a.course_id = c.course_id
GROUP BY 
	1,2,3,4;

DROP TABLE IF EXISTS ahemphill.course_completion_consolidated;
CREATE TABLE IF NOT EXISTS ahemphill.course_completion_consolidated AS
SELECT
	course.user_id,
	course.course_id,
	course.letter_grade,
	CASE
		WHEN course.passed_timestamp IS NOT NULL AND 
		course.passed_timestamp > sub.max_first_attempted THEN sub.max_first_attempted
		WHEN course.passed_timestamp IS NOT NULL AND 
		course.passed_timestamp <= sub.max_first_attempted THEN course.passed_timestamp
		ELSE NULL
	END AS passed_timestamp
FROM
	lms_read_replica.grades_persistentcoursegrade course
LEFT JOIN
	(
	SELECT 
		user_id,
		course_id,
		MAX(first_attempted) AS max_first_attempted
	FROM 
		lms_read_replica.grades_persistentsubsectiongrade
	GROUP BY 
		user_id,
		course_id
	) sub
ON
	course.user_id = sub.user_id
AND
	course.course_id = sub.course_id;

DROP TABLE IF EXISTS ahemphill.fy18_course_completion;
CREATE TABLE IF NOT EXISTS ahemphill.fy18_course_completion AS


(
	SELECT
		cal.date,
		a.course_id,
		b.weekly_engagement_level AS week_1_engagement_level,
		CASE 
			WHEN (c.letter_grade = '' OR c.letter_grade IS NULL) THEN 0
			ELSE 1 
		END AS has_passed_less_strict,
		CASE 
			WHEN DATE(passed_timestamp) <= cal.date THEN 1
			ELSE 0
		END AS has_passed,
		COUNT(1) AS cnt_users
	FROM 
		calendar cal
	JOIN
		user_content_availability_date a
	ON
		cal.date BETWEEN '2016-07-01' AND CURRENT_DATE()
	AND
		content_availability_date = DATE(cal.date) - 120
	JOIN 
		user_activity_engagement_weekly b 
	ON 
		a.user_id = b.user_id
	AND 
		a.course_id = b.course_id
	AND 
		b.week = 'week_1'
	AND 
		b.weekly_engagement_level != 'no_engagement'
	LEFT JOIN 
		ahemphill.course_completion_consolidated c
	ON 
		a.user_id = c.user_id
	AND 
		a.course_id = c.course_id
	GROUP BY 
		1,2,3,4,5
);