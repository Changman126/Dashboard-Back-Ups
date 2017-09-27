
SELECT
	date,
	course_enrollments,
	COUNT(distinct user_id) AS cnt_users
FROM
(
	SELECT 
		user_id,
		CAST(timestamp AS date) AS date,
		COUNT(1) AS course_enrollments
	FROM 
		experimental_events_run14.event_records e
	WHERE
		e.event_type = 'edx.course.enrollment.activated'
		AND e.project = 'tracking_prod'
		AND cast(timestamp as date) BETWEEN '2016-09-01' AND '2016-10-21'
	GROUP BY
		user_id,
		2
) 
GROUP BY
	date,
	course_enrollments