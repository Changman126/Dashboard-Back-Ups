    CREATE TABLE ahemphill.user_first_course_enroll AS
    SELECT
        distinct user_id,
        first_value(course_id) over (course_enrollment) as first_course,
        MIN(first_enrollment_time) OVER (course_enrollment) AS first_enrollment_time
    FROM
        production.d_user_course
    WINDOW
       course_enrollment AS (partition by user_id order by first_enrollment_time asc)

SELECT
	first_engaged_course_w_verification,
	COUNT(1) AS cnt_users,
	COUNT(distinct user_id) AS cnt_distinct_users
FROM
(
	SELECT
		user_id,
		MIN(order_engaged_course) AS first_engaged_course_w_verification
	FROM
	(
		SELECT
			a.user_id,
			first_course,
			a.first_enrollment_time AS first_course_enrollment_time,
			b.course_id,
			b.current_enrollment_mode,
			b.first_enrollment_time,
			c.first_engagement_date,
			row_number() OVER (partition by a.user_id order by c.first_engagement_date ASC) AS order_engaged_course
		FROM
			ahemphill.user_first_course_enroll a
		JOIN
			production.d_user_course b
		ON
			a.user_id = b.user_id
		AND
			a.first_enrollment_time >= '2016-04-11'
		JOIN
		(
			SELECT
				user_id,
				course_id,
				MIN(date) AS first_engagement_date
			FROM 
				production.f_user_activity
			WHERE 
				activity_type != 'ACTIVE'
			GROUP BY 
				1,2
		) c
		ON
			a.user_id = c.user_id
		AND 
			b.course_id = c.course_id
	) a
	WHERE
		current_enrollment_mode = 'verified'
	GROUP BY
		user_id
) a
GROUP BY
	first_engaged_course_w_verification