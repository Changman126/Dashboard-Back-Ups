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
	COUNT(1) as cnt_users,
	SUM(case when cnt_enrolls > 0 then 1 else 0 end) as cnt_users_who_enrolled,
	SUM(cnt_bundles_purchased) AS cnt_bundles_purchased,
	SUM(cnt_enrolls) as cnt_enrolls,
	SUM(cnt_verifs) as cnt_verifs,
	SUM(sum_transactions) as sum_transactions
FROM
(
	SELECT 
		a.user_id,
		a.variation_name,
		a.experiment_path,
		cnt_bundles_purchased,
		cnt_verifs,
		sum_transactions,
		COUNT(b.course_id) as cnt_enrolls
	FROM 
		ahemphill.tmp_optimizely_exposure_daily_deduped a 
	LEFT JOIN
		ahemphill.bundle_purchases c
	ON
		a.user_id = c.user_id
	LEFT JOIN
		production.d_user_course b
	ON 
		a.user_id = b.user_id
	AND 
		b.first_enrollment_time >= a.first_exposure_timestamp
	AND
		b.course_id IN
		(
		'course-v1:MichiganX+UX2+3T2016',
        'course-v1:MichiganX+UX3+3T2016',
        'course-v1:MichiganX+UX501x+3T2016',
        'course-v1:MichiganX+UX504x+1T2017',
        'course-v1:MichiganX+UX509x+2T2017',
        'course-v1:MichiganX+UXD5+1T2017',
        'course-v1:MichiganX+UXD6+1T2017',
        'course-v1:MichiganX+UXR5+1T2017',
        'course-v1:MichiganX+UXR6+1T2017',
        'course-v1:UCSanDiegoX+DS220x+1T2018',
        'course-v1:UCSanDiegoX+DSE200x+2T2017',
        'course-v1:UCSanDiegoX+DSE210x+3T2017',
        'course-v1:UCSanDiegoX+DSE230x+1T2018',
        'course-v1:UBCx+HtC1x+2T2017',
        'course-v1:UBCx+HtC2x+2T2017',
        'course-v1:UBCx+SoftConst1x+3T2017',
        'course-v1:UBCx+SoftConst2x+3T2017',
        'course-v1:UBCx+SoftEng1x+1T2018',
        'course-v1:UBCx+SoftEngPrjx+1T2018',
        'course-v1:UBCx+SPD2x+2T2015',
        'course-v1:UBCx+SPD2x+2T2016',
        'course-v1:UBCx+SPD3x+2T2016',
        'course-v1:UBCx+SPD3x+3T2015' 
			)
	WHERE
		a.experiment_name = 'Program Purchase Test with Discount'
		AND 
			a.variation_name IN
			(
			'Original Program Page',
			'One Click Purchase Program Page'
			)
	GROUP BY
		a.user_id,
		a.variation_name,
		a.experiment_path,
		cnt_bundles_purchased,
		cnt_verifs,
		sum_transactions
) a
GROUP BY
	1

DROP TABLE IF EXISTS ahemphill.bundle_purchases;
CREATE TABLE IF NOT EXISTS ahemphill.bundle_purchases AS

SELECT
	user_id,
	SUM(CASE WHEN cnt_courses_purchased IN (4,9) THEN 1 ELSE 0 END) AS cnt_bundles_purchased,
	SUM(cnt_courses_purchased) AS cnt_verifs,
	SUM(sum_transactions) AS sum_transactions
FROM
(
	SELECT
		b.user_id,
		payment_ref_id,
		COUNT(order_course_id) AS cnt_courses_purchased,
		SUM(transaction_amount_per_item) AS sum_transactions
	FROM
		finance.f_orderitem_transactions a 
	JOIN
		production.d_user b
	ON
		a.order_username = b.user_username
	AND
		order_course_id IN
		(
			'course-v1:MichiganX+UX2+3T2016',
	        'course-v1:MichiganX+UX3+3T2016',
	        'course-v1:MichiganX+UX501x+3T2016',
	        'course-v1:MichiganX+UX504x+1T2017',
	        'course-v1:MichiganX+UX509x+2T2017',
	        'course-v1:MichiganX+UXD5+1T2017',
	        'course-v1:MichiganX+UXD6+1T2017',
	        'course-v1:MichiganX+UXR5+1T2017',
	        'course-v1:MichiganX+UXR6+1T2017',
	        'course-v1:UCSanDiegoX+DS220x+1T2018',
	        'course-v1:UCSanDiegoX+DSE200x+2T2017',
	        'course-v1:UCSanDiegoX+DSE210x+3T2017',
	        'course-v1:UCSanDiegoX+DSE230x+1T2018',
	        'course-v1:UBCx+HtC1x+2T2017',
	        'course-v1:UBCx+HtC2x+2T2017',
	        'course-v1:UBCx+SoftConst1x+3T2017',
	        'course-v1:UBCx+SoftConst2x+3T2017',
	        'course-v1:UBCx+SoftEng1x+1T2018',
	        'course-v1:UBCx+SoftEngPrjx+1T2018',
	        'course-v1:UBCx+SPD2x+2T2015',
	        'course-v1:UBCx+SPD2x+2T2016',
	        'course-v1:UBCx+SPD3x+2T2016',
	        'course-v1:UBCx+SPD3x+3T2015' 
		)
		AND transaction_type = 'sale'
		AND transaction_audit_code = 'PURCHASE_ONE'
		AND transaction_date >= '2017-06-01'
	GROUP BY
		b.user_id,
		payment_ref_id
) a
GROUP BY
	user_id;





