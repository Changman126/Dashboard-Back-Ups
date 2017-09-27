SELECT
	a.cnt_courses_enrolled,
	a.enrollment_year,
	COUNT(1) AS cnt_users,
	COUNT(1) * 100.0/b.cnt_enrolled_users AS pct_of_users,
	(COUNT(1) * a.cnt_courses_enrolled) as cnt_courses_enrolled,
	(COUNT(1) * a.cnt_courses_enrolled) * 100.0/b.cnt_enrolls AS pct_of_enrolls
FROM
(
	SELECT
		user_id,
		CASE 
		when first_enrollment_time between '2014-01-01' and '2014-12-31' then '2014'
		when first_enrollment_time between '2015-01-01' and '2015-12-31' then '2015'
		when first_enrollment_time between '2016-01-01' and '2016-12-31' then '2016'
		END as enrollment_year,
		count(1) AS cnt_courses_enrolled
	FROM 
		production.d_user_course
	WHERE 
		first_enrollment_time between '2014-01-01' and '2016-12-31'
	GROUP BY 
		1,2
) a
JOIN
	(
	SELECT
		CASE 
		when first_enrollment_time between '2014-01-01' and '2014-12-31' then '2014'
		when first_enrollment_time between '2015-01-01' and '2015-12-31' then '2015'
		when first_enrollment_time between '2016-01-01' and '2016-12-31' then '2016'
		END as enrollment_year,
		count(distinct user_id) AS cnt_enrolled_users,
		count(1) as cnt_enrolls
	FROM 
		production.d_user_course
	WHERE 
		first_enrollment_time between '2014-01-01' and '2016-12-31'
	GROUP BY 
		1
	) b
ON
	a.enrollment_year = b.enrollment_year
WHERE 
	a.enrollment_year IS NOT NULL
GROUP BY
	a.cnt_courses_enrolled,
	a.enrollment_year,
	b.cnt_enrolls,
	b.cnt_enrolled_users