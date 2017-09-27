SELECT
	a.course_id,
	a.week,
	a.weekly_engagement_level,
	COUNT(a.user_id) AS cnt_users,
	c.cnt_week_1_engaged_users
FROM 
	business_intelligence.user_activity_engagement_weekly a 
JOIN
(
	SELECT
		user_id,
		course_id
	FROM
		business_intelligence.user_activity_engagement_weekly
	WHERE
		weekly_engagement_level IN ('minimal_engagement', 'high_engagement')
	AND
		week = 'week_1'
) b
ON
    a.user_id = b.user_id
AND
    a.course_id = b.course_id
AND
    week != 'week_1'
JOIN
(
	SELECT
		course_id,
		COUNT(user_id) AS cnt_week_1_engaged_users
	FROM
		business_intelligence.user_activity_engagement_weekly
	WHERE
		weekly_engagement_level IN ('minimal_engagement', 'high_engagement')
	AND
		week = 'week_1'
	GROUP BY 
		course_id
) c
ON
	a.course_id = c.course_id
GROUP BY
	a.course_id,
	a.week,
	a.weekly_engagement_level,
	c.cnt_week_1_engaged_users
