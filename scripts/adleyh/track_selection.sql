DROP TABLE IF EXISTS ahemphill.track_selection_results_stg;
CREATE TABLE IF NOT EXISTS ahemphill.track_selection_results_stg AS

SELECT
	MIN(a.timestamp) AS first_exposure_timestamp,
	a.user_id,
	a.experiment_id,
	a.experiment_name,
	a.variation_id,
	a.variation_name,
	a.path,
	REGEXP_SUBSTR(replace(replace(a.path, '%3', ':'), '%2','+'),
	 '/course_modes/choose/([^/+]+(/|\+)[^/+]+(/|\+)[^/?]+)/', 1, 1, '', 1) AS course_id
FROM 
	experiment_exposure a 
JOIN
(
	SELECT 
		user_id, 
		path, 
		COUNT(distinct variation_name)
	FROM 
		experiment_exposure
	WHERE 
		experiment_id = 8426223218
	GROUP BY 
		1,2
	HAVING 
		COUNT(distinct variation_name) = 1
) b
ON 
	a.user_id = b.user_id
AND 
	a.path = b.path
AND 
	a.experiment_id = 8426223218
GROUP BY
	2,3,4,5,6,7;

DROP TABLE IF EXISTS ahemphill.track_selection_results;
CREATE TABLE IF NOT EXISTS ahemphill.track_selection_results AS
SELECT
	variation_name,
	course_id,
	CASE WHEN cnt_prior_verifs = 0 THEN 'never_purchased' ELSE 'purchased' END AS has_purchased_in_past,
	COUNT(1) AS cnt_users,
	COUNT(unique_transaction_id) AS cnt_transactions,
	SUM(CASE WHEN DATE(order_timestamp) = DATE(first_exposure_timestamp) THEN transaction_amount_per_item ELSE 0 END) AS sum_bookings_day_of_exposure,
	SUM(transaction_amount_per_item) AS sum_bookings_lifetime
FROM 
	ahemphill.track_selection_results_stg a
JOIN 
	production.d_user b
ON 
	a.user_id = b.user_id
LEFT JOIN 
	finance.f_orderitem_transactions c
ON 
	b.user_username = c.order_username
AND 
	a.course_id = c.order_course_id
AND 
	c.transaction_type = 'sale'
AND 
	c.order_timestamp  >= a.first_exposure_timestamp
AND 
	c.order_product_class = 'seat'
LEFT JOIN
	(
		SELECT
			a.user_id,
			COUNT(first_verified_enrollment_time) AS cnt_prior_verifs
		FROM
			ahemphill.track_selection_results_stg a
		JOIN
			production.d_user_course b
		ON
			a.user_id = b.user_id
		AND
			a.course_id != b.course_id
		GROUP BY
			1
	) d
ON
	a.user_id = d.user_id
GROUP BY 
	variation_name,
	course_id,
	3;

SELECT 
	variation_name,
	sum(cnt_users) as cnt_users ,
	sum(cnt_transactions) as cnt_transactions,
	sum(cnt_transactions)/sum(cnt_users) as purchase_rate,
	sum(sum_bookings_day_of_exposure) as sum_bookings_day_of_exposure,
	sum(sum_bookings_lifetime) as sum_bookings_lifetime
 FROM 
 	ahemphill.track_selection_results
GROUP BY
	variation_name;

SELECT 
	variation_name,
	has_purchased_in_past,
	sum(cnt_users) as cnt_users ,
	sum(cnt_transactions) as cnt_transactions,
	sum(cnt_transactions)/sum(cnt_users) as purchase_rate,
	sum(sum_bookings_day_of_exposure) as sum_bookings_day_of_exposure,
	sum(sum_bookings_lifetime) as sum_bookings_lifetime
 FROM 
 	ahemphill.track_selection_results
GROUP BY
	variation_name,
	has_purchased_in_past




