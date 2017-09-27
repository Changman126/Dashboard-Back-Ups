
SELECT
	week,
	is_engaged,
	a.course_id,
	COUNT(1) AS cnt_users
FROM
(
	SELECT
		a.user_id,
		a.course_id,
		CASE
			WHEN b.user_id IS NOT NULL THEN 'engaged'
			ELSE 'not_engaged'
		END AS is_engaged,
		'old course outline' AS week
	FROM
		production.d_user_course a
	LEFT JOIN
		(
			SELECT
				user_id,
				course_id,
				MIN(date) AS min_date
			FROM
				production.f_user_activity
			WHERE
				date BETWEEN '2017-04-07' AND '2017-04-21'
			AND
				activity_type != 'ACTIVE'
			GROUP BY
				user_id,
				course_id
		) b
	ON
		a.user_id = b.user_id
	AND
		a.course_id = b.course_id
	WHERE
		a.first_enrollment_time BETWEEN '2017-04-07' AND '2017-04-21'

	UNION ALL

	SELECT
		a.user_id,
		a.course_id,
		CASE
			WHEN b.user_id IS NOT NULL THEN 'engaged'
			ELSE 'not_engaged'
		END AS is_engaged,
		'new course outline' AS week
	FROM
		production.d_user_course a
	LEFT JOIN
		(
			SELECT
				user_id,
				course_id,
				MIN(date) AS min_date
			FROM
				production.f_user_activity
			WHERE
				date BETWEEN '2017-04-28' and '2017-05-12'
			AND
				activity_type != 'ACTIVE'
			GROUP BY
				user_id,
				course_id
		) b
	ON
		a.user_id = b.user_id
	AND
		a.course_id = b.course_id
	WHERE
		a.first_enrollment_time BETWEEN '2017-04-28' and '2017-05-12'
) a
JOIN 
	course_master b
ON 
	a.course_id = b.course_id
AND 
	b.pacing_type = 'self_paced'
AND 
	b.course_start_date <= '2017-04-20'
GROUP BY 
	week,
	is_engaged,
	a.course_id;

---

SELECT
	week,
	is_verified,
	a.course_id,
	COUNT(1) AS cnt_users
FROM
(
	SELECT
		a.user_id,
		a.course_id,
		CASE
			WHEN b.user_id IS NOT NULL THEN 'verified'
			ELSE 'not_verified'
		END is_verified,
		'old course outline' AS week
	FROM
		production.d_user_course a
	LEFT JOIN
		(
			SELECT
				user_id,
				course_id,
				first_verified_enrollment_time
			FROM
				production.d_user_course
			WHERE
				date(first_verified_enrollment_time) BETWEEN '2017-04-07' AND '2017-04-21'
		) b
	ON
		a.user_id = b.user_id
	AND
		a.course_id = b.course_id
	WHERE
		a.first_enrollment_time BETWEEN '2017-04-07' AND '2017-04-21'

	UNION ALL

	SELECT
		a.user_id,
		a.course_id,
		CASE
			WHEN b.user_id IS NOT NULL THEN 'verified'
			ELSE 'not_verified'
		END is_verified,
		'new course outline' AS week
	FROM
		production.d_user_course a
	LEFT JOIN
		(
			SELECT
				user_id,
				course_id,
				first_verified_enrollment_time
			FROM
				production.d_user_course
			WHERE
				date(first_verified_enrollment_time) BETWEEN '2017-04-28' and '2017-05-12'
		) b
	ON
		a.user_id = b.user_id
	AND
		a.course_id = b.course_id
	WHERE
		a.first_enrollment_time BETWEEN '2017-04-28' and '2017-05-12'
) a
JOIN 
	course_master b
ON 
	a.course_id = b.course_id
AND 
	b.pacing_type = 'self_paced'
AND 
	b.course_start_date <= '2017-04-20'
GROUP BY 
	week,
	is_verified,
	a.course_id;



