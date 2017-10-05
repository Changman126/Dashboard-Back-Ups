--collect data at the user level for subsection grades.

DROP TABLE IF EXISTS business_intelligence.course_grading_subsection_user;
CREATE TABLE IF NOT EXISTS business_intelligence.course_grading_subsection_user AS

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
	cad.content_availability_date,
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
	business_intelligence.user_content_availability_date cad
ON
	grade.user_id = cad.user_id
AND
	grade.course_id = cad.course_id;

--aggregate user level data to get grading summary at subsection level

DROP TABLE IF EXISTS business_intelligence.course_grading_subsection_summary;
CREATE TABLE IF NOT EXISTS business_intelligence.course_grading_subsection_summary AS

SELECT
	course_id,
	usage_key,
	earned_graded,
	possible_graded,
	pct_subsection_grade,
	COUNT(1) AS cnt_users
FROM 
	business_intelligence.course_grading_subsection_user
GROUP BY 
	course_id,
	usage_key,
	earned_graded,
	possible_graded,
	pct_subsection_grade;

--join user level data to the top level course summary

DROP TABLE IF EXISTS business_intelligence.course_grading_user;
CREATE TABLE IF NOT EXISTS business_intelligence.course_grading_user AS

SELECT 
	course.user_id,
	course.course_id,
	course.letter_grade,
	course.percent_grade,
	user_grade.cnt_attempts,
	sub.cnt_subsections,
	user_grade.cnt_attempts * 100.0/sub.cnt_subsections AS pct_progress,
	user_grade.current_enrollment_mode,
	user_grade.enrollment_date,
	user_grade.content_availability_date,
	DATE(completion.passed_timestamp) AS date_passed,
	DATEDIFF('day', DATE(user_grade.content_availability_date), DATE(completion.passed_timestamp)) AS days_content_availability_to_pass
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
		COUNT(attempt_date) AS cnt_attempts
	FROM
		business_intelligence.course_grading_subsection_user
	GROUP BY
		user_id,
		course_id,
		current_enrollment_mode,
		enrollment_date,
		content_availability_date
) user_grade
ON 
	course.user_id = user_grade.user_id
AND 
	course.course_id = user_grade.course_id
JOIN
(
	SELECT
		course_id,
		COUNT(DISTINCT usage_key) AS cnt_subsections
	FROM
		business_intelligence.course_grading_subsection_user
	GROUP BY
		course_id
) sub
ON 
	course.course_id = sub.course_id
JOIN
	business_intelligence.course_completion_user completion
ON
	course.user_id = completion.user_id
AND
	course.course_id = completion.course_id;

--condensed view of course level grading to provide high level course grading stats

DROP TABLE IF EXISTS business_intelligence.course_grading_summary;
CREATE TABLE IF NOT EXISTS business_intelligence.course_grading_summary AS

SELECT 
	course_id,
	letter_grade,
	percent_grade,
	current_enrollment_mode,
	CASE
		WHEN date_passed IS NOT NULL THEN 1
		ELSE 0
	END AS has_passed,
	COUNT(1) AS cnt_users
FROM 
    business_intelligence.course_grading_user
GROUP BY
	course_id,
	letter_grade,
	percent_grade,
	current_enrollment_mode,
	5;

--Creating the Summary Table for Grading and Problem Submissions Over Time Summary Table

CREATE TABLE IF NOT EXISTS business_intelligence.course_grading_user_time (
	date DATE,
	user_id INTEGER,
	course_id VARCHAR(255),
	percent_grade FLOAT,
	cnt_total_problems_attempted_daily INTEGER,
	cnt_total_problems_attempted_cumulative INTEGER
);

--Dummy insert to initialize table and allow inserts of only new date rows for each daily update

INSERT INTO business_intelligence.course_grading_user_time (date)
SELECT
	'2012-08-31'
FROM
	business_intelligence.course_grading_user_time
HAVING
	COUNT(date)=0;

--Temporary table for Grades Over Time

DROP TABLE IF EXISTS tmp_grades_over_time;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_grades_over_time ON COMMIT PRESERVE ROWS AS

SELECT
	DATE(received_at) AS date,
	CAST(user_id AS INTEGER) AS user_id,
	course_id,
	MAX(percent_grade) AS percent_grade
FROM
	experimental_events_run14.event_records
JOIN
	(
		SELECT
			MAX(date) AS latest_date
		FROM
			grade_user_time
	) max_date
ON
	DATE(received_at) > max_date.latest_date
WHERE
	event_type = 'edx.grades.course.grade_calculated'
GROUP BY
	DATE(received_at),
	user_id,
	course_id;

-- Temporary table for number of Problems Attempted
DROP TABLE IF EXISTS tmp_problem_attempts;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_problem_attempts ON COMMIT PRESERVE ROWS AS

SELECT
	date,
	user_id,
	course_id,
	cnt_problem_activity AS cnt_total_problems_attempted_daily
FROM
	business_intelligence.activity_engagement_user_daily
JOIN
	(
		SELECT
			MAX(date) AS latest_date
		FROM
			grade_user_time
	) max_date
ON
	date > max_date.latest_date;

--Insert Statement to combine tmp_problem_attemps and tmp_grades_over_time

INSERT INTO business_intelligence.course_grading_user_time (

	SELECT
		COALESCE(
			problems.date,
			grades.date
				) AS date,
		COALESCE(
			problems.user_id,
			grades.user_id
				) AS user_id,
		COALESCE(
			problems.course_id,
			grades.course_id
				) AS course_id,
		MAX(ISNULL(grades.percent_grade, 0)) OVER (PARTITION BY COALESCE(problems.user_id, grades.user_id), COALESCE(problems.course_id,grades.course_id) ORDER BY COALESCE(problems.date,grades.date)) AS percent_grade,
		ISNULL(cnt_total_problems_attempted_daily, 0) AS cnt_total_problems_attempted_daily,
		SUM(cnt_total_problems_attempted_daily) OVER (PARTITION BY COALESCE(problems.user_id, grades.user_id), COALESCE(problems.course_id,grades.course_id) ORDER BY COALESCE(problems.date,grades.date)) AS cnt_total_problems_attempted_cumulative
	FROM
		tmp_problem_attempts problems
	FULL JOIN
		tmp_grades_over_time grades
	ON
		grades.date = problems.date
	AND
		grades.user_id = problems.user_id
	AND
		grades.course_id = problems.course_id
	GROUP BY
		1,
		2,
		3,
		grades.percent_grade,
		cnt_total_problems_attempted_daily
);	

DROP TABLE IF EXISTS tmp_grades_over_time;
DROP TABLE IF EXISTS tmp_problem_attempts;
