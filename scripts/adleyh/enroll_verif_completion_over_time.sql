DROP TABLE IF EXISTS ahemphill.course_enrollment_verification_completion_over_time;
CREATE TABLE ahemphill.course_enrollment_verification_completion_over_time AS

SELECT
	a.date,
	a.course_id,
	a.metric,
	a.value
FROM
(
SELECT
	date(a.first_enrollment_time) AS date,
	a.course_id,
	'enrollment' AS metric,
	COUNT(1) AS value
FROM
	d_user_course a
GROUP BY
	1,2,3

UNION ALL

SELECT
	date(a.first_verified_enrollment_time) AS date,
	a.course_id,
	'verification' AS metric,
	COUNT(a.first_verified_enrollment_time) AS value
FROM
	d_user_course a
GROUP BY
	1,2,3

UNION ALL

SELECT
	date(a.modified_date) AS date,
	a.course_id,
	'completions' AS metric,
	SUM(a.has_passed) AS value
FROM
	d_user_course_certificate a
GROUP BY
	1,2,3
) a