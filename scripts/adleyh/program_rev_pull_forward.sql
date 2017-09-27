DROP TABLE IF EXISTS ahemphill.program_verify_first_course;
CREATE TABLE IF NOT EXISTS ahemphill.program_verify_first_course AS
--get the first course and verification status for all users that meet below criteria
SELECT
	a.program_id,
	b.program_title,
	b.program_type,
	c.user_id,
	MAX(c.course_id) AS course_id,
	MAX(CASE WHEN c.current_enrollment_mode = 'verified' THEN 1 ELSE 0 END) AS has_verified,
	MAX(CASE WHEN d.passed_timestamp IS NOT NULL THEN 1 ELSE 0 END) AS has_passed
FROM
(
	--get all program_ids which have courses in the program after the first with verifications
	SELECT 
		distinct program_id
	from 
		production.d_program_course a
	join 
		course_stats_summary b
	on 
		a.course_id = b.course_id
	AND 
		a.program_slot_number > 1
	AND 
		sum_verifications > 0 
) a 
JOIN 
	production.d_program_course b
ON 
	a.program_id = b.program_id
AND 
	b.program_slot_number = 1
join 
	production.d_user_course c
on 
	b.course_id = c.course_id
LEFT JOIN
	business_intelligence.course_completion_user d
ON
	c.user_id = d.user_id
AND
	c.course_id = d.course_id
GROUP BY
	1,2,3,4;


DROP TABLE IF EXISTS ahemphill.program_verify_stg;
CREATE TABLE IF NOT EXISTS ahemphill.program_verify_stg AS

--for all users that enrolled in the first course of an eligible program, see 
--how many follow on courses they enrolled and verified in
SELECT
	a.program_id,
	a.program_title,
	a.program_type,
	a.user_id,
	a.course_id AS first_course_id,
	a.has_verified AS first_course_verified,
	a.has_passed AS first_course_passed,
	b.program_slot_number,
	MAX(CASE WHEN c.course_id IS NOT NULL THEN 1 ELSE 0 END) AS has_enrolled,
	MAX(CASE WHEN c.current_enrollment_mode = 'verified' THEN 1 ELSE 0 END) AS has_verified,
	MAX(CASE WHEN d.passed_timestamp IS NOT NULL THEN 1 ELSE 0 END) AS has_passed
FROM
	ahemphill.program_verify_first_course a
JOIN
	production.d_program_course b
ON
	a.program_id = b.program_id
AND
    a.course_id != b.course_id
AND
    b.program_slot_number > 1
LEFT JOIN
	production.d_user_course c
ON
	a.user_id = c.user_id
AND
	b.course_id = c.course_id
LEFT JOIN
	business_intelligence.course_completion_user d
ON
	a.user_id = d.user_id
AND
	c.course_id = d.course_id
GROUP BY
	1,2,3,4,5,6,7,8;

--collapse table to be one row per (user, program)
DROP TABLE IF EXISTS ahemphill.program_verify;
CREATE TABLE IF NOT EXISTS ahemphill.program_verify AS

SELECT
	program_id,
	program_type,
	program_title,
	first_course_verified,
	first_course_passed,
	second_course_enrolled,
	second_course_verified,
	second_course_passed,
	third_course_enrolled,
	third_course_verified,
	third_course_passed,
	fourth_course_enrolled,
	fourth_course_verified,
	fourth_course_passed,
	COUNT(user_id) AS cnt_users
FROM
(
	SELECT
		program_id,
		program_type,
		program_title,
		user_id,
		first_course_verified,
		first_course_passed,
		MAX(CASE WHEN program_slot_number = 2 THEN has_enrolled ELSE 0 END) AS second_course_enrolled,
		MAX(CASE WHEN program_slot_number = 2 THEN has_verified ELSE 0 END) AS second_course_verified,
		MAX(CASE WHEN program_slot_number = 2 THEN has_passed ELSE 0 END) AS second_course_passed,
		MAX(CASE WHEN program_slot_number = 3 THEN has_enrolled ELSE 0 END) AS third_course_enrolled,
		MAX(CASE WHEN program_slot_number = 3 THEN has_verified ELSE 0 END) AS third_course_verified,
		MAX(CASE WHEN program_slot_number = 3 THEN has_passed ELSE 0 END) AS third_course_passed,
		MAX(CASE WHEN program_slot_number = 4 THEN has_enrolled ELSE 0 END) AS fourth_course_enrolled,
		MAX(CASE WHEN program_slot_number = 4 THEN has_verified ELSE 0 END) AS fourth_course_verified,
		MAX(CASE WHEN program_slot_number = 4 THEN has_passed ELSE 0 END) AS fourth_course_passed
	FROM
		ahemphill.program_verify_stg a 
	GROUP BY
		1,2,3,4,5,6
) a
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14;

SELECT
	a.program_type,
	a.program_title,
	course_price,
	SUM(CASE WHEN first_course_verified = 1 THEN cnt_users ELSE 0 END) * 100.0/SUM(cnt_users) AS first_course_vtr,
	SUM(cnt_users) AS cnt_first_course_users_verify,
	SUM(CASE WHEN first_course_verified = 1 AND second_course_verified = 1 THEN cnt_users ELSE 0 END) * 100.0/SUM(CASE WHEN first_course_verified = 1 THEN cnt_users ELSE 0 END) AS second_course_vtr_after_first_course_verify,
	SUM(CASE WHEN first_course_verified = 1 AND second_course_verified = 1 THEN cnt_users ELSE 0 END) AS cnt_second_course_users_verify,
	SUM(CASE WHEN first_course_verified = 1 AND second_course_verified = 1 AND third_course_verified = 1 THEN cnt_users ELSE 0 END) * 100.0/
	SUM(CASE WHEN first_course_verified = 1 AND second_course_verified = 1 THEN cnt_users ELSE 0 END) AS third_course_vtr_after_first_second_course_verify,
	SUM(CASE WHEN first_course_verified = 1 AND second_course_verified = 1 AND third_course_verified = 1 THEN cnt_users ELSE 0 END) AS cnt_third_course_users_verify
FROM 
	ahemphill.program_verify a 
join
(
select 
program_type, program_title, max(course_seat_price) AS course_price, avg(course_seat_price)
from production.d_program_course a 
join course_master b
on a.course_id = b.course_id
and b.course_start_date >= '2017-01-01'
and program_slot_number = 1
and program_type = 'MicroMasters'
group by 1,2

) b
on a.program_type = b.program_type
and a.program_title = b.program_title
GROUP BY 
	1,2,3


