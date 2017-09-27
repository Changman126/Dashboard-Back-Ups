DROP TABLE IF EXISTS ahemphill.tmp_optimizely_exposure_daily_deduped;
CREATE TABLE ahemphill.tmp_optimizely_exposure_daily_deduped AS
SELECT
	a.*
FROM
	ahemphill.tmp_optimizely_exposure_daily a
JOIN
	(
		SELECT
			user_id,
			experiment_name,
			experiment_path,
			COUNT(DISTINCT variation_name) AS cnt_variations
		FROM
			ahemphill.tmp_optimizely_exposure_daily
		GROUP BY
			user_id,
			experiment_name,
			experiment_path
		HAVING
			COUNT(DISTINCT variation_name) = 1
	) b
ON
	a.user_id = b.user_id
AND
	a.experiment_name = b.experiment_name;

SELECT
	variation_name,
	COUNT(1) AS cnt_users,
	SUM(cnt_enrolls) AS cnt_enrolls,
	SUM(CASE WHEN cnt_enrolls > 0 THEN 1 ELSE 0 END) AS cnt_enrolled_users,
	SUM(cnt_verifications) AS cnt_verifications,
	SUM(CASE WHEN cnt_verifications > 0 THEN 1 ELSE 0 END) AS cnt_verified_users,
	SUM(sum_bookings) AS sum_bookings
FROM
(
	SELECT
		a.user_id,
		a.variation_name,
		a.cnt_enrolls,
		COUNT(d.order_course_id) AS cnt_verifications,
		SUM(d.transaction_amount_per_item) AS sum_bookings
	FROM
	(
		SELECT
			a.user_id,
			b.user_username,
			a.first_exposure_timestamp,
			a.variation_name,
			COUNT(c.course_id) AS cnt_enrolls
		FROM 
			ahemphill.tmp_optimizely_exposure_daily_deduped a 
		JOIN 
			production.d_user b
		ON 
			a.user_id = b.user_id
		and 
			experiment_name = 'Minimal Homepage'
		LEFT JOIN
			production.d_user_course c
		ON 
			a.user_id = c.user_id
		AND 
			c.first_enrollment_time >= a.first_exposure_timestamp
		GROUP BY
			a.user_id,
			b.user_username,
			a.first_exposure_timestamp,
			a.variation_name
	) a
	LEFT JOIN
		finance.f_orderitem_transactions d
	ON 
		a.user_username = d.order_username
	AND 
		d.transaction_type = 'sale'
	AND 
		d.transaction_audit_code = 'PURCHASE_ONE'
	AND
		d.order_product_detail = 'verified'
	AND 
		DATE(d.transaction_date) >= DATE(a.first_exposure_timestamp)
	GROUP BY 
		a.user_id,
		a.variation_name,
		a.cnt_enrolls
) a
GROUP BY
	1