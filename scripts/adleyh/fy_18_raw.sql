SELECT
	weekly_engagement_level,
	SUM(cnt_users)
FROM 
	user_activity_engagement_daily_agg
WHERE
	week = 'week_1'
	and date >= CURRENT_DATE()-90
GROUP BY 
	1