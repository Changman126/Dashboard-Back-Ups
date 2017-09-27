--overall stats

SELECT
	user_country,
	user_status,
	COUNT(DISTINCT user_id)
FROM
(
	SELECT
		user_id,
		user_email,
		user_country,
		CASE
			WHEN MAX(first_verified_enrollment_time) IS NOT NULL THEN 'verified'
			WHEN MAX(has_passed) = 1 THEN 'completed'
			ELSE 'audit'
		END AS user_status
	FROM
	(
		SELECT
			a.user_id,
			b.user_email,
			a.course_id,
			b.user_last_location_country_code AS user_country,
			a.first_verified_enrollment_time,
			CASE
				WHEN c.passed_timestamp IS NOT NULL THEN 1
				ELSE 0
			END AS has_passed
		FROM 
			production.d_user_course a
		JOIN 
			production.d_user b
		ON 
			a.user_id = b.user_id
		AND 
			a.first_enrollment_time >= '2017-01-01'
		AND 
			b.user_last_location_country_code IN
			(
			'US',
			'IN',
			'MX',
			'ES'

			)
		AND 
			a.current_enrollment_mode IN ('verified','audit')
		AND 
			(2017 - user_year_of_birth) BETWEEN 18 AND 54
		LEFT JOIN
			business_intelligence.course_completion_user c
		ON
			a.user_id = c.user_id
		AND
			a.course_id = c.course_id
	) a
	GROUP BY
		1,2,3
) a
GROUP BY 
	1,2;

--use this to pull email addresses
SELECT
	user_id,
	user_email,
	user_country,
	CASE
		WHEN MAX(first_verified_enrollment_time) IS NOT NULL THEN 'verified'
		WHEN MAX(has_passed) = 1 THEN 'completed'
		ELSE 'audit'
	END AS user_status
FROM
(
	SELECT
		a.user_id,
		b.user_email,
		a.course_id,
		b.user_last_location_country_code AS user_country,
		a.first_verified_enrollment_time,
		CASE
			WHEN c.passed_timestamp IS NOT NULL THEN 1
			ELSE 0
		END AS has_passed
	FROM 
		production.d_user_course a
	JOIN 
		production.d_user b
	ON 
		a.user_id = b.user_id
	AND 
		a.first_enrollment_time >= '2017-01-01'
	AND 
		b.user_last_location_country_code IN
		(
		'US',
		'IN',
		'MX',
		'ES'

		)
	AND 
		a.current_enrollment_mode IN ('verified','audit')
	AND 
		(2017 - user_year_of_birth) BETWEEN 18 AND 54
	LEFT JOIN
		business_intelligence.course_completion_user c
	ON
		a.user_id = c.user_id
	AND
		a.course_id = c.course_id
) a
WHERE
	user_country = 'US'
GROUP BY
	1,2,3
HAVING
	CASE
		WHEN MAX(first_verified_enrollment_time) IS NOT NULL THEN 'verified'
		WHEN MAX(has_passed) = 1 THEN 'completed'
		ELSE 'audit'
	END = 'audit'
LIMIT 25000