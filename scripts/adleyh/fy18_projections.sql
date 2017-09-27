--fy18 p(verify)

SELECT
	CASE
		WHEN date BETWEEN '2011-07-01' AND '2012-06-30' THEN 2012
		WHEN date BETWEEN '2012-07-01' AND '2013-06-30' THEN 2013 
		WHEN date BETWEEN '2013-07-01' AND '2014-06-30' THEN 2014 
		WHEN date BETWEEN '2014-07-01' AND '2015-06-30' THEN 2015 
		WHEN date BETWEEN '2015-07-01' AND '2016-06-30' THEN 2016 
		WHEN date BETWEEN '2016-07-01' AND '2017-06-30' THEN 2017 
	END AS fiscal_year,
	SUM(cnt_enrolls_vtr) AS sum_enrolls,
	SUM(cnt_verifications) AS sum_verifications,
	SUM(cnt_verifications) * 100.0/SUM(cnt_enrolls_vtr)
FROM 
	course_stats_time
GROUP BY
	1;

--fy18 avg seat price

SELECT
	CASE
		WHEN DATE(transaction_date)  BETWEEN '2011-07-01' AND '2012-06-30' THEN 2012
		WHEN DATE(transaction_date)  BETWEEN '2012-07-01' AND '2013-06-30' THEN 2013 
		WHEN DATE(transaction_date)  BETWEEN '2013-07-01' AND '2014-06-30' THEN 2014 
		WHEN DATE(transaction_date)  BETWEEN '2014-07-01' AND '2015-06-30' THEN 2015 
		WHEN DATE(transaction_date)  BETWEEN '2015-07-01' AND '2016-06-30' THEN 2016 
		WHEN DATE(transaction_date)  BETWEEN '2016-07-01' AND '2017-06-30' THEN 2017 
	END AS fiscal_year,
	AVG(transaction_amount_per_item) AS sum_bookings
FROM 
	finance.f_orderitem_transactions a
JOIN 
	course_master b
ON 
	a.order_course_id = b.course_id
AND 
	b.is_wl = 0
AND 
	a.order_product_class = 'seat'
AND 
	transaction_date IS NOT NULL
AND 
	transaction_type = 'sale'
GROUP BY
	1;

--avg enrolls per user

SELECT 
	AVG(COALESCE(cnt_enrolls,0)) AS avg_enrolls
FROM
(
	SELECT
		a.user_id,
		COUNT(1) AS cnt_enrolls
	FROM 
		production.d_user a
	LEFT JOIN 
		production.d_user_course b
	ON 
		a.user_id = b.user_id
	WHERE 
		a.user_account_creation_time >= '2016-07-01'
	GROUP BY 
		a.user_id
) a


SELECT 
	fiscal_year_reg,
	cnt_enrollments/cnt_reg_users
FROM
(
	SELECT
		CASE
			WHEN user_account_creation_time BETWEEN '2011-07-01' AND '2012-07-01' THEN 2012
			WHEN user_account_creation_time BETWEEN '2012-07-01' AND '2013-07-01' THEN 2013 
			WHEN user_account_creation_time BETWEEN '2013-07-01' AND '2014-07-01' THEN 2014 
			WHEN user_account_creation_time BETWEEN '2014-07-01' AND '2015-07-01' THEN 2015 
			WHEN user_account_creation_time BETWEEN '2015-07-01' AND '2016-07-01' THEN 2016 
			WHEN user_account_creation_time BETWEEN '2016-07-01' AND '2017-07-01' THEN 2017 
		END AS fiscal_year_reg,
		CASE
			WHEN first_enrollment_time BETWEEN '2011-07-01' AND '2012-07-01' THEN 2012
			WHEN first_enrollment_time BETWEEN '2012-07-01' AND '2013-07-01' THEN 2013
			WHEN first_enrollment_time BETWEEN '2013-07-01' AND '2014-07-01' THEN 2014 
			WHEN first_enrollment_time BETWEEN '2014-07-01' AND '2015-07-01' THEN 2015 
			WHEN first_enrollment_time BETWEEN '2015-07-01' AND '2016-07-01' THEN 2016 
			WHEN first_enrollment_time BETWEEN '2016-07-01' AND '2017-07-01' THEN 2017 
		END AS fiscal_year_enroll,
		COUNT(DISTINCT a.user_id) AS cnt_reg_users,
		COUNT(1) AS cnt_enrollments
	FROM
		production.d_user a
	LEFT JOIN
		production.d_user_course b
	ON
		a.user_id = b.user_id
	GROUP BY 
		1,2
) a
WHERE
	fiscal_year_reg = fiscal_year_enroll