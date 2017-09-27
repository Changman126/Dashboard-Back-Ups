
SELECT
	c.user_id,
	d.current_enrollment_mode,
	d.course_id,
	a.order_course_id,
	b.course_end_date,
	d.first_enrollment_time,
	CASE WHEN a.order_username IS NULL THEN 1 ELSE 0 END AS refund,
	DATEDIFF('day',d.first_enrollment_time, b.course_end_date) AS days_enrolled_prior_course_end_date
FROM
	production.d_user_course d
JOIN 
	course_master b
ON 
	d.course_id = b.course_id
AND
	d.first_verified_enrollment_time IS NOT NULL 
AND 
	b.course_partner = 'Microsoft'
JOIN 
	production.d_user c
ON 
	d.user_id = c.user_id
LEFT JOIN
	finance.f_orderitem_transactions a
ON 
	c.user_username = a.order_username
AND 
	a.order_course_id = d.course_id
AND 
	a.transaction_type = 'refund'
AND 
	orderitem_audit_code = 'REFUNDED_BALANCE_MATCHING'

;
SELECT
	course_id,
	SUM(CASE WHEN days_enrolled_prior_course_end_date BETWEEN 0 AND 13 THEN refund ELSE 0 END) AS cnt_refund_enrolled_2_weeks,
	SUM(CASE WHEN days_enrolled_prior_course_end_date BETWEEN 0 AND 13 THEN 1 ELSE 0 END) AS cnt_verified_enrolled_2_weeks,
	SUM(CASE WHEN days_enrolled_prior_course_end_date BETWEEN 0 AND 13 THEN refund ELSE 0 END) * 100.0/
	SUM(CASE WHEN days_enrolled_prior_course_end_date BETWEEN 0 AND 13 THEN 1 ELSE 0 END) AS refund_rate_2_weeks,
	SUM(CASE WHEN days_enrolled_prior_course_end_date BETWEEN 0 AND 27 THEN refund ELSE 0 END) AS cnt_refund_enrolled_4_weeks,
	SUM(CASE WHEN days_enrolled_prior_course_end_date BETWEEN 0 AND 27 THEN 1 ELSE 0 END) AS cnt_verified_enrolled_4_weeks,
	SUM(CASE WHEN days_enrolled_prior_course_end_date BETWEEN 0 AND 27 THEN refund ELSE 0 END) * 100.0/
	SUM(CASE WHEN days_enrolled_prior_course_end_date BETWEEN 0 AND 27 THEN 1 ELSE 0 END) AS refund_rate_4_weeks,
	SUM(refund) AS cnt_refunds_lifetime,
	COUNT(1) AS cnt_verified_lifetime,
	SUM(refund) * 100.0/COUNT(1) AS refund_rate_lifetime
FROM
(
	SELECT
		c.user_id,
		d.current_enrollment_mode,
		d.course_id,
		a.order_course_id,
		b.course_end_date,
		d.first_enrollment_time,
		CASE WHEN a.order_username IS NOT NULL THEN 1 ELSE 0 END AS refund,
		DATEDIFF('day', d.first_enrollment_time, b.course_end_date) AS days_enrolled_prior_course_end_date
	FROM
		production.d_user_course d
	JOIN 
		course_master b
	ON 
		d.course_id = b.course_id
	AND
		d.first_verified_enrollment_time IS NOT NULL 
	AND 
		b.course_partner = 'Microsoft'
	JOIN 
		production.d_user c
	ON 
		d.user_id = c.user_id
	LEFT JOIN
		finance.f_orderitem_transactions a
	ON 
		c.user_username = a.order_username
	AND 
		a.order_course_id = d.course_id
	AND 
		a.transaction_type = 'refund'
	AND 
		orderitem_audit_code = 'REFUNDED_BALANCE_MATCHING'
) a 
GROUP BY
	course_id