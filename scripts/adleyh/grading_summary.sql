--collect data at the user level for subsection grades.

DROP TABLE IF EXISTS tmp_subsection_grading_user;	
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_subsection_grading_user ON COMMIT PRESERVE ROWS AS	

SELECT
	grade.user_id,
	grade.course_id,
	grade.usage_key,
	grade.earned_graded,
	grade.possible_graded,
	CASE
		WHEN grade.possible_graded = 0 THEN 0
		ELSE grade.earned_graded * 100.0/grade.possible_graded 
	END AS pct_subsection_grade,
	user_course.current_enrollment_mode,
	DATE(user_course.first_enrollment_time) AS enrollment_date,
	CASE 
		WHEN user_course.first_enrollment_time >= course.start_time THEN DATE(user_course.first_enrollment_time)
		ELSE DATE(course.start_time)
	END AS content_availability_date,
	DATE(grade.first_attempted) AS attempt_date
FROM 
	lms_read_replica.grades_persistentsubsectiongrade grade
JOIN
	production.d_user_course user_course
ON
	grade.user_id = user_course.user_id
AND
	grade.course_id = user_course.course_id
JOIN
	production.d_course course
ON
	grade.course_id = course.course_id;

--aggregate user level data to get grading summary at subsection level

DROP TABLE IF EXISTS subsection_grading_summary;
CREATE TABLE IF NOT EXISTS subsection_grading_summary AS

SELECT
	course_id,
	usage_key,
	earned_graded,
	possible_graded,
	pct_subsection_grade,
	COUNT(1) AS cnt_users
FROM 
	tmp_subsection_grading_user
GROUP BY 
	course_id,
	usage_key,
	earned_graded,
	possible_graded,
	pct_subsection_grade;

--join user level data to the top level course summary and aggregate

DROP TABLE IF EXISTS course_grading_detailed;
CREATE TABLE IF NOT EXISTS course_grading_detailed AS

SELECT 
	course.course_id,
	course.letter_grade,
	course.percent_grade,
	sub.cnt_attempts,
	sub.cnt_subsections,
	sub.cnt_attempts * 100.0/sub.cnt_subsections AS pct_progress,
	sub.current_enrollment_mode,
	sub.enrollment_date,
	sub.content_availability_date,
	DATE(course.passed_timestamp) AS date_passed,
	DATEDIFF('day', DATE(sub.content_availability_date), DATE(course.passed_timestamp)) AS days_content_availability_to_pass,
	COUNT(1) AS cnt_users
FROM 
    lms_read_replica.grades_persistentcoursegrade course
JOIN 
	(
		SELECT
			user_id,
			course_id,
			current_enrollment_mode,
			enrollment_date,
			content_availability_date,
			COUNT(attempt_date) AS cnt_attempts,
			COUNT(usage_key) AS cnt_subsections
		FROM
			tmp_subsection_grading_user
		GROUP BY
			user_id,
			course_id,
			current_enrollment_mode,
			enrollment_date,
			content_availability_date
	) sub
ON 
	course.user_id = sub.user_id
AND 
	course.course_id = sub.course_id
GROUP BY
	course.course_id,
	course.letter_grade,
	course.percent_grade,
	sub.cnt_attempts,
	sub.cnt_subsections,
	sub.cnt_attempts * 100.0/sub.cnt_subsections,
	sub.current_enrollment_mode,
	sub.enrollment_date,
	sub.content_availability_date,
	DATE(course.passed_timestamp),
	DATEDIFF('day', DATE(sub.content_availability_date), DATE(course.passed_timestamp));

--condensed view of course level grading to provide high level course grading stats

DROP TABLE IF EXISTS course_grading_summary;
CREATE TABLE IF NOT EXISTS course_grading_summary AS

SELECT 
	course_id,
	letter_grade,
	percent_grade,
	current_enrollment_mode,
	CASE
		WHEN date_passed IS NOT NULL THEN 1
		ELSE 0
	END AS has_passed,
	SUM(cnt_users) AS cnt_users
FROM 
    course_grading_detailed course
GROUP BY
	course_id,
	letter_grade,
	percent_grade,
	current_enrollment_mode,
	5;

DROP TABLE IF EXISTS tmp_subsection_grading_user;