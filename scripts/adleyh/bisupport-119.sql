DROP TABLE ahemphill.bisupport119;

CREATE TABLE ahemphill.bisupport119 (email VARCHAR(64), transaction_id VARCHAR(64));

COPY ahemphill.bisupport119 FROM LOCAL '/Users/adleyhemphill/Documents/paypal_transactions.csv' DELIMITER ',';

CREATE TABLE ahemphill.donations_demographics AS

SELECT
	COALESCE(c.user_id, d.user_id) AS user_id,
	COALESCE(a.order_username, d.user_username) AS user_username,
	b.email AS paypal_email,
	COALESCE(c.user_email, d.user_email) AS user_useremail,
	a.transaction_id,
	transaction_date,
	transaction_payment_gateway_id,
	donation_source,
	transaction_amount,
	order_course_id,
	COALESCE(c.user_year_of_birth, d.user_year_of_birth) AS user_year_of_birth,
	COALESCE(c.user_level_of_education, d.user_level_of_education) AS user_level_of_education,
	COALESCE(c.user_gender, d.user_gender) AS user_gender,
	COALESCE(c.user_account_creation_time, d.user_account_creation_time) AS user_account_creation_time,
	COALESCE(c.user_last_location_country_code, d.user_last_location_country_code) AS user_last_location_country_code
FROM
(
SELECT
	order_username,
	transaction_id,
	transaction_date,
	transaction_payment_gateway_id,
	'edx.org/donate' AS donation_source,
	transaction_amount,
	order_course_id

FROM
	finance.f_orderitem_transactions a
WHERE
	transaction_payment_gateway_id = 'paypal' 
	AND order_course_id is null
	AND transaction_date BETWEEN '2016-01-01' AND '2016-12-31'

UNION ALL

SELECT
	order_username,
	transaction_id,
	transaction_date,
	transaction_payment_gateway_id,
	'banner' AS donation_source,
	transaction_amount,
	order_course_id

FROM
	finance.f_orderitem_transactions a
WHERE
	order_product_class = 'donation'
	AND transaction_date BETWEEN '2016-01-01' AND '2016-12-31'

) a
LEFT JOIN
	ahemphill.bisupport119 b
ON
	a.transaction_id = b.transaction_id
LEFT JOIN
	production.d_user c
ON
	a.order_username = c.user_username
LEFT JOIN
	production.d_user d
ON
	b.email = d.user_email;


SELECT course_id, current_enrollment_mode, count(1) AS cnt_users
FROM d_user_course a
JOIN 
(
SELECT DISTINCT user_id AS user_id
FROM
ahemphill.donations_demographics b
) b
on a.user_id = b.user_id
AND a.first_enrollment_time >= '2016-01-01'
GROUP BY 1,2