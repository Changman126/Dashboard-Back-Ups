CREATE TABLE ahemphill.user_enrolls_by_year AS

SELECT
	user_id,
	YEAR(first_enrollment_time) AS enroll_year,
	COUNT(1) AS cnt_enrolls,
	COUNT(first_verified_enrollment_time) AS cnt_verified_enrollments
FROM
	production.d_user_course
GROUP BY 
	1,2;

SELECT 
	YEAR(user_account_creation_time) AS year_registered,
	CASE 
		WHEN b.cnt_verified_enrollments > 0 THEN 'verified'
		WHEN b.cnt_enrolls > 0 THEN 'enrolled'
		ELSE 'no_enrolls'
	END AS status_in_registration_year,
	CASE 
		WHEN c.cnt_verified_enrollments > 0 THEN 'verified'
		WHEN c.cnt_enrolls > 0 THEN 'enrolled'
		ELSE 'no_enrolls'
	END AS status_in_following_year,
	COUNT(1) AS cnt_users

FROM 
	production.d_user a
LEFT JOIN 
	ahemphill.user_enrolls_by_year b
ON
	a.user_id = b.user_id
AND
	YEAR(user_account_creation_time) = b.enroll_year
LEFT JOIN 
	ahemphill.user_enrolls_by_year c
ON
	a.user_id = c.user_id
AND
	YEAR(user_account_creation_time) + 1 = c.enroll_year
GROUP BY
	1,2,3