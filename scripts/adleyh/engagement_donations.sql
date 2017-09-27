SELECT
	a.engagement_level,
	SUM(c.transaction_amount) AS sum_donations,
	COUNT(a.user_id) AS cnt_users,
	SUM(c.transaction_amount)/count(distinct a.user_id) AS sum_donations_per_user
FROM 
(
	SELECT
		user_id,
		CASE
			when MAX(numeric_engagement) = 2 THEN 'high_engagement'
			when MAX(numeric_engagement) = 1 THEN 'minimal_engagement'
			ELSE 'no_engagement'
		END AS engagement_level
	FROM 
	(
		SELECT
			*,
			CASE
				when weekly_engagement_level = 'high_engagement' THEN 2
				when weekly_engagement_level = 'minimal_engagement' THEN 1
				ELSE 0
			END AS numeric_engagement
		FROM 
			ahemphill.user_activity_engagement_weekly_summary a
		WHERE 
			a.week = 'week_1'
	) a 
	GROUP BY 
		1

)a
JOIN 
	production.d_user b
ON 
	a.user_id = b.user_id
LEFT JOIN 
	finance.f_orderitem_transactions c
ON 
	b.user_username = c.order_username
AND 
	c.order_product_class = 'donation'
AND 
	c.transaction_id IS NOT NULL
GROUP BY
1