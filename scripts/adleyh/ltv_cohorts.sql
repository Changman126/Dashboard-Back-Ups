SELECT
	a.fiscal_year_reg,
	a.fiscal_year_transaction,
	c.cnt_registered,
	d.cnt_enrolled_users,
	a.total_bookings,
	a.total_bookings/c.cnt_registered AS yearly_value,
	a.total_bookings/d.cnt_enrolled_users AS yearly_value_per_enrolled_users,
	a.cnt_verifications*100.0/d.cnt_enrollments AS vtr,
	a.cnt_verified_users*100.0/c.cnt_registered AS pct_verified_users,
	a.cnt_verified_users*100.0/d.cnt_enrolled_users AS pct_verified_users_who_enroll
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
			WHEN DATE(transaction_date) BETWEEN '2011-07-01' AND '2012-07-01' THEN 2012
			WHEN DATE(transaction_date) BETWEEN '2012-07-01' AND '2013-07-01' THEN 2013 
			WHEN DATE(transaction_date) BETWEEN '2013-07-01' AND '2014-07-01' THEN 2014 
			WHEN DATE(transaction_date) BETWEEN '2014-07-01' AND '2015-07-01' THEN 2015 
			WHEN DATE(transaction_date) BETWEEN '2015-07-01' AND '2016-07-01' THEN 2016 
			WHEN DATE(transaction_date) BETWEEN '2016-07-01' AND '2017-07-01' THEN 2017 
		END AS fiscal_year_transaction,
		COUNT(b.order_course_id) AS cnt_verifications,
		COUNT(DISTINCT b.order_username) AS cnt_verified_users,
		SUM(COALESCE(transaction_amount, 0)) AS total_bookings
	FROM
		production.d_user a
	LEFT JOIN
		finance.f_orderitem_transactions b
	ON
		a.user_username = b.order_username
	JOIN
    	business_intelligence.course_master e
	ON
	    b.order_course_id = e.course_id
	AND
	    e.is_wl = 0
	GROUP BY
		1,2
) a
LEFT JOIN
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
		COUNT(1) AS cnt_registered
	FROM
		production.d_user
	GROUP BY 
		1
) c
ON
	a.fiscal_year_reg = c.fiscal_year_reg
LEFT JOIN
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
		COUNT(DISTINCT a.user_id) AS cnt_enrolled_users,
		COUNT(1) AS cnt_enrollments
	FROM
		production.d_user a
	LEFT JOIN
		production.d_user_course b
	ON
		a.user_id = b.user_id
	GROUP BY 
		1,2
) d
ON
	a.fiscal_year_transaction = d.fiscal_year_enroll
AND
	a.fiscal_year_reg = d.fiscal_year_reg
WHERE
	a.fiscal_year_transaction IS NOT NULL;
---

SELECT
	a.user_last_location_country_code,
	a.fiscal_year_reg,
	a.fiscal_year_transaction,
	c.cnt_registered,
	d.cnt_enrolled_users,
	a.total_bookings,
	a.total_bookings/c.cnt_registered AS yearly_value,
	a.total_bookings/d.cnt_enrolled_users AS yearly_value_per_enrolled_users
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
			WHEN DATE(transaction_date) BETWEEN '2011-07-01' AND '2012-07-01' THEN 2012
			WHEN DATE(transaction_date) BETWEEN '2012-07-01' AND '2013-07-01' THEN 2013 
			WHEN DATE(transaction_date) BETWEEN '2013-07-01' AND '2014-07-01' THEN 2014 
			WHEN DATE(transaction_date) BETWEEN '2014-07-01' AND '2015-07-01' THEN 2015 
			WHEN DATE(transaction_date) BETWEEN '2015-07-01' AND '2016-07-01' THEN 2016 
			WHEN DATE(transaction_date) BETWEEN '2016-07-01' AND '2017-07-01' THEN 2017 
		END AS fiscal_year_transaction,
		a.user_last_location_country_code,
		SUM(COALESCE(transaction_amount, 0)) AS total_bookings
	FROM
		production.d_user a
	LEFT JOIN
		finance.f_orderitem_transactions b
	ON
		a.user_username = b.order_username
	JOIN
    	business_intelligence.course_master e
	ON
	    b.order_course_id = e.course_id
	AND
	    e.is_wl = 0
	GROUP BY
		1,2,3
) a
LEFT JOIN
(
	SELECT
		CASE
			WHEN user_account_creation_time BETWEEN '2012-07-01' AND '2013-07-01' THEN 2013 
			WHEN user_account_creation_time BETWEEN '2013-07-01' AND '2014-07-01' THEN 2014 
			WHEN user_account_creation_time BETWEEN '2014-07-01' AND '2015-07-01' THEN 2015 
			WHEN user_account_creation_time BETWEEN '2015-07-01' AND '2016-07-01' THEN 2016 
			WHEN user_account_creation_time BETWEEN '2016-07-01' AND '2017-07-01' THEN 2017 
		END AS fiscal_year_reg,
		user_last_location_country_code,
		COUNT(1) AS cnt_registered
	FROM
		production.d_user
	WHERE
		user_last_location_country_code IN
		(
			'US',
			'IN',
			'BR',
			'CA',
			'GB',
			'MX'
		)
	GROUP BY 
		1,2
) c
ON
	a.fiscal_year_reg = c.fiscal_year_reg
AND
	a.user_last_location_country_code = c.user_last_location_country_code
LEFT JOIN
(
	SELECT
		CASE
			WHEN user_account_creation_time BETWEEN '2012-07-01' AND '2013-07-01' THEN 2013 
			WHEN user_account_creation_time BETWEEN '2013-07-01' AND '2014-07-01' THEN 2014 
			WHEN user_account_creation_time BETWEEN '2014-07-01' AND '2015-07-01' THEN 2015 
			WHEN user_account_creation_time BETWEEN '2015-07-01' AND '2016-07-01' THEN 2016 
			WHEN user_account_creation_time BETWEEN '2016-07-01' AND '2017-07-01' THEN 2017 
		END AS fiscal_year_reg,
		CASE
			WHEN first_enrollment_time BETWEEN '2013-07-01' AND '2014-07-01' THEN 2014 
			WHEN first_enrollment_time BETWEEN '2014-07-01' AND '2015-07-01' THEN 2015 
			WHEN first_enrollment_time BETWEEN '2015-07-01' AND '2016-07-01' THEN 2016 
			WHEN first_enrollment_time BETWEEN '2016-07-01' AND '2017-07-01' THEN 2017 
		END AS fiscal_year_enroll,
		a.user_last_location_country_code,
		COUNT(DISTINCT a.user_id) AS cnt_enrolled_users
	FROM
		production.d_user a
	LEFT JOIN
		production.d_user_course b
	ON
		a.user_id = b.user_id
	WHERE
		user_last_location_country_code IN
		(
			'US',
			'IN',
			'BR',
			'CA',
			'GB',
			'MX'
		)
	GROUP BY 
		1,2,3
) d
ON
	a.fiscal_year_transaction = d.fiscal_year_enroll
AND
	a.fiscal_year_reg = d.fiscal_year_reg
AND
	a.user_last_location_country_code = d.user_last_location_country_code
WHERE
	a.fiscal_year_transaction IS NOT NULL
AND
	a.user_last_location_country_code IN
		(
			'US',
			'IN',
			'BR',
			'CA',
			'GB',
			'MX'
		);