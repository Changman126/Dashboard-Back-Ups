--retention of previous years' users
--we do this to understand what our likely population of users is to start with in FY18

SELECT
	YEAR(user_account_creation_time) AS year_registered,
	CASE 
		WHEN 
			b.user_id IS NOT NULL THEN '2016 enroll' 
		ELSE 'no 2016 enroll' 
	END AS has_enroll_in_2016,
COUNT(1) AS cnt_users
FROM 
	production.d_user a
LEFT JOIN
(
	SELECT 
		distinct user_id
	FROM 
		production.d_user_course
	WHERE 
		YEAR(DATE(first_enrollment_time)) = '2016'
) b
ON 
	a.user_id = b.user_id
GROUP BY 
	1,2

DROP TABLE ahemphill.viable_user_enroll;
CREATE TABLE ahemphill.viable_user_enroll AS

SELECT
	user_id
FROM
	production.d_user_course
WHERE
	first_enrollment_time >= '2016-05-17'
GROUP BY
	user_id

CREATE TABLE ahemphill.viable_user_enroll_country AS

SELECT
	a.user_id,
	user_last_location_country_code
FROM
	production.d_user_course a
JOIN
	production.d_user b
ON
	a.user_id = b.user_id
AND
	first_enrollment_time >= '2016-05-17'
GROUP BY
	a.user_id,
	user_last_location_country_code

--Understand our viable existing user base for baselining purposes
--This is based on the number of new accounts created in the last year
--Note: this is a slightly conservative estimate, but in general the number lines up with what we'd expect
--given the above.

SELECT
	SUM(CASE WHEN user_account_creation_time >= '2016-05-17' THEN 1 ELSE 0 END) AS acquired_1y
FROM 
	production.d_user;

--enrolled users: based on acquisition date

SELECT
	COUNT(DISTINCT a.user_id)
FROM
	(
		SELECT
			user_id
		FROM
			production.d_user
		WHERE
		    user_account_creation_time >= '2016-05-17'
	) a
JOIN
	production.d_user_course b
ON
	a.user_id = b.user_id
AND
	b.first_enrollment_time >= '2016-05-17'

--active users

SELECT
	COUNT(DISTINCT a.user_id)
FROM
	ahemphill.viable_user_enroll a
JOIN
	production.f_user_activity b
ON
	a.user_id = b.user_id
AND
	b.date >= '2016-05-17';

--engaged users

SELECT
	COUNT(DISTINCT a.user_id)
FROM
	ahemphill.viable_user_enroll a
JOIN
	production.f_user_activity b
ON
	a.user_id = b.user_id
AND
	b.date >= '2016-05-17'
AND
	b.activity_type != 'ACTIVE';

--bucket learners based on engagement, days engaged within 7d of enroll
--Note: we bucket learners for the entire period based on the max number of days engaged in ALL courses

DROP TABLE IF EXISTS ahemphill.mimimally_highly_engaged_users_enroll_date;
CREATE TABLE IF NOT EXISTS ahemphill.mimimally_highly_engaged_users_enroll_date AS

SELECT
	user_id,
	CASE WHEN MAX(cnt_days_engaged_first_7d) < 2 THEN 'minimally' ELSE 'highly' END AS engagement_level,
	COUNT(1) AS cnt_enrolls

FROM
(
	SELECT
		a.user_id,
		c.course_id,
		c.content_availability_date,
		c.first_verified_enrollment_time,
		CASE
			WHEN c.first_verified_enrollment_time IS NOT NULL THEN 1
			ELSE 0
		END AS is_verified,
		SUM(CASE 
			WHEN DATEDIFF('day', date(content_availability_date), b.date) BETWEEN 0 AND 6 THEN 1
			ELSE 0
		END) AS cnt_days_engaged_first_7d,
		COUNT(DISTINCT b.date) AS cnt_days_engaged
	FROM 
		ahemphill.viable_user_enroll a
	JOIN
		(
			--need to find a (user,course_id) content availability date in order to find the right 7d window to look at
			SELECT
				a.user_id,
				a.course_id,
				a.first_verified_enrollment_time,
				CASE
					WHEN first_enrollment_time >= start_time THEN first_enrollment_time
					ELSE start_time
				END AS content_availability_date
			FROM
				production.d_user_course a
			JOIN
				production.d_course b
			ON
				a.course_id = b.course_id
			AND 
				CASE
					WHEN first_enrollment_time >= start_time THEN first_enrollment_time
					ELSE start_time
				END >= '2016-05-17'
		) c
	ON
		a.user_id = c.user_id
	-- only looking at engaged users, so an inner join is fine
	JOIN
		(
			SELECT
				user_id,
				course_id,
				date
			FROM
				production.f_user_activity
			WHERE
				date >= '2016-05-17'
			AND
				activity_type != 'ACTIVE'
			GROUP BY
				user_id,
				course_id,
				date
		) b
	ON
		a.user_id = b.user_id
	AND
		b.course_id = c.course_id
	GROUP BY
		a.user_id,
		c.course_id,
		c.content_availability_date,
		c.first_verified_enrollment_time,
		5
) a
GROUP BY
	user_id;

-- probability to verify
-- Note: this is at the course level to ensure that when we multiply P(Verify) by Avg Enrolls per year, we get a realistic
-- number of verifications
SELECT
	SUM(CASE WHEN cnt_days_engaged_first_7d <2 AND is_verified = 1 THEN cnt_overall_enrolls ELSE 0 END)*100.0/
	SUM(CASE WHEN cnt_days_engaged_first_7d <2 THEN cnt_overall_enrolls ELSE 0 END) AS p_verify_minimal,
	SUM(CASE WHEN cnt_days_engaged_first_7d >=2 AND is_verified = 1 THEN cnt_overall_enrolls ELSE 0 END)*100.0/
	SUM(CASE WHEN cnt_days_engaged_first_7d >=2 THEN cnt_overall_enrolls ELSE 0 END) AS p_verify_high
FROM
(
	SELECT
		cnt_days_engaged_first_7d,
		cnt_days_engaged,
		is_verified,
		COUNT(DISTINCT user_id) AS cnt_distinct_users,
		COUNT(1) AS cnt_overall_enrolls
	FROM
	(
		SELECT
			a.user_id,
			c.course_id,
			c.content_availability_date,
			c.first_verified_enrollment_time,
			CASE
				WHEN c.first_verified_enrollment_time IS NOT NULL THEN 1
				ELSE 0
			END AS is_verified,
			SUM(CASE 
				WHEN DATEDIFF('day', date(content_availability_date), b.date) BETWEEN 0 AND 6 THEN 1
				ELSE 0
			END) AS cnt_days_engaged_first_7d,
			COUNT(DISTINCT b.date) AS cnt_days_engaged
		FROM 
			ahemphill.viable_user_enroll a
		JOIN
			(
				SELECT
					a.user_id,
					a.course_id,
					a.first_verified_enrollment_time,
					CASE
						WHEN first_enrollment_time >= start_time THEN first_enrollment_time
						ELSE start_time
					END AS content_availability_date
				FROM
					production.d_user_course a
				JOIN
					production.d_course b
				ON
					a.course_id = b.course_id
				AND 
					CASE
						WHEN first_enrollment_time >= start_time THEN first_enrollment_time
						ELSE start_time
					END >= '2016-05-17'
			) c
		ON
			a.user_id = c.user_id

		JOIN
			(
				SELECT
					user_id,
					course_id,
					date
				FROM
					production.f_user_activity
				WHERE
					date >= '2016-05-17'
				AND
					activity_type != 'ACTIVE'
				GROUP BY
					user_id,
					course_id,
					date
			) b
		ON
			a.user_id = b.user_id
		AND
			b.course_id = c.course_id
		GROUP BY
			a.user_id,
			c.course_id,
			c.content_availability_date,
			c.first_verified_enrollment_time,
			5
	) a
	GROUP BY
		cnt_days_engaged_first_7d,
		cnt_days_engaged,
		is_verified
) a;


--enrollments per engagement group

SELECT
	engagement_level,
	COUNT(1) AS cnt_enrolls,
	COUNT(DISTINCT a.user_id) AS cnt_users,
	count(1)/count(distinct a.user_id)
FROM
	ahemphill.mimimally_highly_engaged_users_enroll_date a
JOIN
	production.d_user_course b
ON
	a.user_id = b.user_id
AND
	b.first_enrollment_time >= '2016-05-17'
GROUP BY
    engagement_level;

--avg seat price
SELECT
	engagement_level,
	avg(course_seat_price)
FROM
(
	SELECT
		a.user_id,
		a.engagement_level,
		b.course_id,
		c.course_seat_price
	FROM
		ahemphill.mimimally_highly_engaged_users_enroll_date a
	JOIN
		production.d_user_course b
	ON
		a.user_id = b.user_id
	AND 
		b.first_verified_enrollment_time >= '2016-05-17'
	JOIN
		production.d_course_seat c
	ON
		b.course_id = c.course_id
	AND 
		c.course_seat_type = 'verified'
	AND
		c.course_seat_price > 0
) a
GROUP BY
	engagement_level;

/*
***********
EXTRA STUFF, NOT CURRENTLY USED IN CALCULATION
***********
*/


--enrollment decay factor. not used at the moment.

	select 
	course_number,
	run,
	avg(sum_enrolls)
	from 
	(
		SELECT
		a.course_number,
		case when b.course_run_number =1 then 'first' else 'not_first' end as run,
		c.sum_enrolls
		from
		(
			select
			course_number,
			count( course_run_number) from course_master
			where course_start_date >= '2016-04-01'
			group by 1
			having count(1) > 2
		) a
		join course_master b
		on a.course_number = b.course_number
		join course_stats_summary c
		on b.course_id = c.course_id
	) a
	group by 1,2
order by course_number, course_run_number asc;


--can't remember what this is for...


SELECT
	CASE
		WHEN days_engaged <3 THEN 'minimally'
		ELSE 'highly'
	END AS engagement_level,
	is_verified,
	COUNT(user_id) AS cnt_users
FROM
(
	SELECT
		a.user_id,
		CASE 
			WHEN min_verified_date IS NOT NULL THEN 'verified' 
			ELSE 'not verified' 
		END AS is_verified,
		CASE
			WHEN min_verified_date IS NULL THEN COUNT(DISTINCT date)
			ELSE SUM(CASE WHEN date <= min_verified_date THEN 1 ELSE 0 END)
		END AS days_engaged
	FROM
	(
		SELECT 
			user_id, 
			date
		FROM 
			production.f_user_activity
		WHERE 
			activity_type != 'ACTIVE'
			AND date >= '2016-04-01'
		GROUP BY 
			user_id,
			date
	) a
	LEFT JOIN 
	(
		SELECT 
			user_id, 
			MIN(DATE(first_verified_enrollment_time)) AS min_verified_date
		FROM 
			production.d_user_course
		WHERE 
			first_verified_enrollment_time IS NOT NULL
		AND 
			date(first_verified_enrollment_time) >= '2016-04-01'
		GROUP BY 
			user_id
	) b 
	ON 
		a.user_id = b.user_id
	JOIN
	(
		SELECT
			user_id
		FROM
			production.d_user
		WHERE
		      user_account_creation_time >= '2016-04-01'
	) c
	ON 
		a.user_id = c.user_id
	GROUP BY 
		a.user_id,
		2, 
		min_verified_date
) a
WHERE 
	days_engaged > 0 
GROUP BY
	1,2;

-- same thing as above, by country

SELECT
	user_last_location_country_code,
	SUM(CASE WHEN cnt_days_engaged_first_7d <2 THEN cnt_overall_enrolls ELSE 0 END) AS cnt_minimally_engaged,
	SUM(CASE WHEN cnt_days_engaged_first_7d <2 AND is_verified = 1 THEN cnt_overall_enrolls ELSE 0 END) AS cnt_minimially_engaged_verified,
	SUM(CASE WHEN cnt_days_engaged_first_7d >=2 THEN cnt_overall_enrolls ELSE 0 END) AS cnt_highly_engaged,
	SUM(CASE WHEN cnt_days_engaged_first_7d >=2 AND is_verified = 1 THEN cnt_overall_enrolls ELSE 0 END) AS cnt_highly_engaged_verified,
	SUM(CASE WHEN cnt_days_engaged_first_7d <2 AND is_verified = 1 THEN cnt_overall_enrolls ELSE 0 END)*100.0/
	SUM(CASE WHEN cnt_days_engaged_first_7d <2 THEN cnt_overall_enrolls ELSE 0 END) AS p_verify_minimal,
	SUM(CASE WHEN cnt_days_engaged_first_7d >=2 AND is_verified = 1 THEN cnt_overall_enrolls ELSE 0 END)*100.0/
	SUM(CASE WHEN cnt_days_engaged_first_7d >=2 THEN cnt_overall_enrolls ELSE 0 END) AS p_verify_high
FROM
(
SELECT
	user_last_location_country_code,
	cnt_days_engaged_first_7d,
	cnt_days_engaged_first_14d,
	cnt_days_engaged,
	is_verified,
	verified_enroll_same_day,
	COUNT(DISTINCT user_id) AS cnt_distinct_users,
	COUNT(1) AS cnt_overall_enrolls

FROM
(
	SELECT
		a.user_id,
		a.user_last_location_country_code,
		c.course_id,
		c.content_availability_date,
		c.first_verified_enrollment_time,
		CASE
			WHEN c.first_verified_enrollment_time IS NOT NULL THEN 1
			ELSE 0
		END AS is_verified,
		CASE
			WHEN DATE(first_verified_enrollment_time) = DATE(content_availability_date) THEN 1
			ELSE 0
		END AS verified_enroll_same_day,
		SUM(CASE 
			WHEN DATEDIFF('day', date(content_availability_date), b.date) BETWEEN 0 AND 7 THEN 1
			ELSE 0
		END) AS cnt_days_engaged_first_7d,
		SUM(CASE 
			WHEN DATEDIFF('day', date(content_availability_date), b.date) BETWEEN 0 AND 14 THEN 1
			ELSE 0
		END) AS cnt_days_engaged_first_14d,
		COUNT(DISTINCT b.date) AS cnt_days_engaged
	FROM 
		ahemphill.viable_user_enroll_country a
	JOIN
		(
			SELECT
				a.user_id,
				a.course_id,
				a.first_verified_enrollment_time,
				CASE
					WHEN first_enrollment_time >= start_time THEN first_enrollment_time
					ELSE start_time
				END AS content_availability_date
			FROM
				production.d_user_course a
			JOIN
				production.d_course b
			ON
				a.course_id = b.course_id
			AND 
				a.first_enrollment_time >= '2016-05-17'
		) c
	ON
		a.user_id = c.user_id

	JOIN
		(
			SELECT
				user_id,
				course_id,
				date
			FROM
				production.f_user_activity
			WHERE
				date >= '2016-05-17'
			AND
				activity_type != 'ACTIVE'
			GROUP BY
				user_id,
				course_id,
				date
		) b
	ON
		a.user_id = b.user_id
	AND
		b.course_id = c.course_id
	GROUP BY
		a.user_id,
		a.user_last_location_country_code,
		c.course_id,
		c.content_availability_date,
		c.first_verified_enrollment_time,
		5,
		6
) a
GROUP BY
	user_last_location_country_code,
	cnt_days_engaged_first_7d,
	cnt_days_engaged_first_14d,
	cnt_days_engaged,
	is_verified,
	verified_enroll_same_day
) a
GROUP BY
	user_last_location_country_code;