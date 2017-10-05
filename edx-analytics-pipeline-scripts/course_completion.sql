DROP TABLE IF EXISTS business_intelligence.course_completion_user;
CREATE TABLE IF NOT EXISTS business_intelligence.course_completion_user AS
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

DROP TABLE IF EXISTS business_intelligence.course_completion;
CREATE TABLE IF NOT EXISTS business_intelligence.course_completion AS

SELECT
	cal.date,
	content_availability_date.course_id,
	engagement.weekly_engagement_level AS week_1_engagement_level,
	CASE 
		WHEN (grade.letter_grade != '' AND grade.letter_grade IS NOT NULL) THEN 1
		ELSE 0
	END AS has_passed_lifetime,
	CASE 
		WHEN DATE(passed_timestamp) <= cal.date THEN 1
		ELSE 0
	END AS has_passed_120d,
	COUNT(1) AS cnt_users
FROM 
	calendar cal
JOIN
	user_content_availability_date content_availability_date
ON
	content_availability_date = DATE(cal.date) - 120
AND
	cal.date BETWEEN '2016-07-01' AND CURRENT_DATE()
JOIN 
	user_activity_engagement_weekly engagement
ON 
	content_availability_date.user_id = engagement.user_id
AND 
	content_availability_date.course_id = engagement.course_id
AND 
	engagement.week = 'week_1'
AND 
	engagement.weekly_engagement_level != 'no_engagement'
LEFT JOIN 
	business_intelligence.course_completion_user grade
ON 
	content_availability_date.user_id = grade.user_id
AND 
	content_availability_date.course_id = grade.course_id
GROUP BY 
	cal.date,
	content_availability_date.course_id,
	engagement.weekly_engagement_level,
	4,
	5;
