-- aggregate offer level data using condition, range, and benefit
-- single_or_multi_course logic has been validated by Michael Frey

DROP TABLE IF EXISTS voucher_offer;
CREATE TABLE IF NOT EXISTS voucher_offer AS

SELECT
	offers.voucher_id,
	conditional_offers.id AS offer_id,
	conditional_offers.name AS offer_name,
	benefit.type AS discount_type,
	benefit.value AS discount_value,
	COALESCE(conditional_offers.max_global_applications, 10000) AS max_global_applications,
	CASE
		WHEN range.catalog_id IS NOT NULL THEN 'Single Course'
		WHEN range.catalog_query IS NOT NULL THEN 'Multi Course'
		WHEN range.course_catalog IS NOT NULL THEN 'Enterprise'
	END AS single_or_multi_course,
	range.course_seat_types
FROM 
	otto_read_replica.voucher_voucher_offers offers
JOIN 
	otto_read_replica.offer_conditionaloffer conditional_offers
ON
	offers.conditionaloffer_id = conditional_offers.id
JOIN
	otto_read_replica.offer_condition condition
ON
	conditional_offers.condition_id = condition.id
JOIN
	otto_read_replica.offer_range range
ON 
	condition.range_id = range.id
JOIN
	otto_read_replica.offer_benefit benefit
ON
	conditional_offers.benefit_id = benefit.id;

-- aggregate data about the parent coupon

DROP TABLE IF EXISTS voucher_coupon;
CREATE TABLE IF NOT EXISTS voucher_coupon AS

SELECT 
	product.id AS coupon_id,
	product.title AS coupon_name,
	catalog_category.name AS coupon_code_type,
	client.name AS coupon_partner_name,
	order_line.order_id AS coupon_order_id,
	invoice.discount_type AS coupon_discount_type
FROM  
	otto_read_replica.catalogue_product product
JOIN 
	otto_read_replica.catalogue_productcategory category
ON 
	product.id = category.product_id
JOIN
	otto_read_replica.catalogue_category catalog_category
ON 
	category.category_id = catalog_category.id
JOIN
	otto_read_replica.order_line order_line
ON
	product.id = order_line.product_id
JOIN
	otto_read_replica.invoice_invoice invoice
ON
	invoice.order_id = order_line.order_id
JOIN
	otto_read_replica.core_businessclient client
ON
	invoice.business_client_id = client.id;

-- aggregate data about redeemed vouchers

DROP TABLE IF EXISTS voucher_order;
CREATE TABLE IF NOT EXISTS voucher_order AS

SELECT 
	u.user_id,
	app.voucher_id,
	app.date_created AS date_voucher_redeemed,
	app.order_id AS voucher_redemption_order_id,
	finance.payment_ref_id AS voucher_redemption_payment_ref_id,
	order_line.product_id,
	order_line.line_price_before_discounts_incl_tax AS price_pre_discount,
	(order_line.line_price_before_discounts_incl_tax - order_line.line_price_incl_tax) AS discount_amount, 
	order_line.line_price_incl_tax AS price_post_discount,
	catalog.course_id
	
FROM 
	otto_read_replica.voucher_voucherapplication app
JOIN
	otto_read_replica.order_line order_line
ON 
	app.order_id = order_line.order_id
JOIN
	otto_read_replica.catalogue_product catalog
ON
	order_line.product_id = catalog.id
JOIN
	finance.f_orderitem_transactions finance
ON
	app.order_id = finance.order_id
AND
	(finance.transaction_type IS NULL
	OR finance.transaction_type = 'sale')
JOIN
	production.d_user u
ON
	finance.order_username = u.user_username;

-- starting with full voucher list, connect to redeemed vouchers and then link to parent coupons
-- use the combination of voucher_couponvouchers_vouchers and voucher_couponvouchers to map child voucher_id to parent coupon_id

DROP TABLE IF EXISTS voucher_redemption;
CREATE TABLE IF NOT EXISTS voucher_redemption AS

SELECT
	voucher_coupon_derived.coupon_name,
	voucher.code AS voucher_code,
	voucher.usage,
	voucher_coupon_derived.coupon_code_type,
	voucher_coupon_derived.coupon_partner_name,
	voucher_offer_derived.discount_type,
	voucher_offer_derived.discount_value,
	CASE
		WHEN voucher_offer_derived.discount_type = 'Percentage' AND voucher_offer_derived.discount_value = '100.00' THEN 'Enrollment'
		WHEN voucher_offer_derived.discount_type = 'Percentage' AND voucher_offer_derived.discount_value != '100.00' THEN 'Discount'
		ELSE 'N/A'
	END AS voucher_type,
	voucher_offer_derived.single_or_multi_course,
	voucher_offer_derived.max_global_applications,
	voucher_offer_derived.course_seat_types,
	voucher.start_datetime AS coupon_start_date,
	voucher.end_datetime AS coupon_end_date,
	CASE 
		WHEN CURRENT_DATE BETWEEN voucher.start_datetime AND voucher.end_datetime THEN 'active' 
		ELSE 'inactive' 
	END AS active_inactive,
	voucher.num_orders AS cnt_voucher_redemptions,
	voucher_order.voucher_redemption_payment_ref_id,
	voucher_order.date_voucher_redeemed,
	voucher_order.price_pre_discount,
	voucher_order.discount_amount,
	voucher_order.price_post_discount,
	voucher_order.user_id,
	voucher_order.course_id
FROM
	otto_read_replica.voucher_voucher voucher
LEFT JOIN
	voucher_order voucher_order
ON
	voucher.id = voucher_order.voucher_id
JOIN
	otto_read_replica.voucher_couponvouchers_vouchers voucher_coupon
ON
	voucher.id = voucher_coupon.voucher_id
JOIN
	otto_read_replica.voucher_couponvouchers coupon_voucher
ON
	coupon_voucher.id = voucher_coupon.couponvouchers_id
JOIN
	voucher_coupon voucher_coupon_derived
ON
	coupon_voucher.coupon_id = voucher_coupon_derived.coupon_id
JOIN
	voucher_offer voucher_offer_derived
ON
	voucher.id = voucher_offer_derived.voucher_id;


DROP TABLE IF EXISTS tmp_credit_uuid;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_credit_uuid ON COMMIT PRESERVE ROWS AS

SELECT 
	d_user.user_id,
	course.course_key AS course_id,
	request.uuid
FROM 
	lms_read_replica.credit_creditrequest request
JOIN 
	lms_read_replica.credit_creditcourse course
ON 
	request.course_id = course.id
JOIN 
	production.d_user d_user
ON 
	request.username = d_user.user_username;

-- voucher redemption information at the user level

DROP TABLE IF EXISTS voucher_redemption_user_course;
CREATE TABLE IF NOT EXISTS voucher_redemption_user_course AS

SELECT
	redemption.date_voucher_redeemed,
	redemption.user_id,
	credit.uuid AS credit_uuid,
	redemption.course_id,
	redemption.voucher_code,
	redemption.coupon_start_date,
	redemption.coupon_end_date,
	COALESCE(cert.has_passed, 0) AS has_passed,
	COALESCE(activity.latest_activity_date, 'N/A') AS latest_activity_date,
	redemption.coupon_name,
	redemption.coupon_partner_name,
	redemption.coupon_code_type,
	redemption.usage,
	redemption.active_inactive,
	redemption.voucher_type,
	redemption.discount_type,
	redemption.discount_value,
	redemption.price_pre_discount,
	redemption.discount_amount,
	redemption.price_post_discount,
	redemption.voucher_redemption_payment_ref_id
FROM
	voucher_redemption redemption
LEFT JOIN
	production.d_user_course_certificate cert
ON
	redemption.user_id = cert.user_id
AND
	redemption.course_id = cert.course_id
LEFT JOIN
(
	SELECT
		user_id,
		course_id,
		CAST(MAX(date) AS VARCHAR) AS latest_activity_date
	FROM
		production.f_user_activity
	GROUP BY 
		user_id,
		course_id
) activity
ON
	redemption.user_id = activity.user_id
AND
	redemption.course_id = activity.course_id
LEFT JOIN
	tmp_credit_uuid credit
ON
	redemption.user_id = credit.user_id
AND
	redemption.course_id = credit.course_id
WHERE
	redemption.user_id IS NOT NULL;

-- roll up voucher redemption data to the course level

DROP TABLE IF EXISTS voucher_redemption_course_summary;
CREATE TABLE IF NOT EXISTS voucher_redemption_course_summary AS

SELECT
	course_id,
	coupon_name,
	coupon_partner_name,
	coupon_code_type,
	usage,
	active_inactive,
	voucher_type,
	discount_type,
	discount_value,
	COUNT(course_id) AS cnt_redemptions,
	COALESCE(SUM(price_pre_discount), 0) AS sum_price_pre_discount,
	COALESCE(SUM(discount_amount), 0) AS sum_discount_amount,
	COALESCE(SUM(price_post_discount), 0) AS sum_price_post_discount
FROM
	voucher_redemption a
GROUP BY
	course_id,
	coupon_name,
	coupon_partner_name,
	coupon_code_type,
	usage,
	coupon_start_date,
	coupon_end_date,
	active_inactive,
	voucher_type,
	discount_type,
	discount_value,
	max_global_applications;

-- roll up voucher redemption data to the coupon level

DROP TABLE IF EXISTS voucher_redemption_coupon_summary;
CREATE TABLE IF NOT EXISTS voucher_redemption_coupon_summary AS

SELECT
	coupon_name,
	coupon_code_type,
	coupon_partner_name,
	usage,
	single_or_multi_course,
	course_seat_types,
	coupon_start_date,
	coupon_end_date,
	active_inactive,
	voucher_type,
	discount_type,
	discount_value,
	COUNT(DISTINCT voucher_code) AS cnt_unique_codes_issued,
	COUNT(course_id) AS cnt_redemptions,
	CASE
		WHEN usage = 'Single use' THEN COUNT(DISTINCT voucher_code)
		ELSE max_global_applications * COUNT(DISTINCT voucher_code) 
	END AS max_total_redemptions,
	COUNT(course_id) * 100.0/(CASE
		WHEN usage = 'Single use' THEN COUNT(DISTINCT voucher_code)
		ELSE max_global_applications * COUNT(DISTINCT voucher_code) 
	END) AS redemption_rate,
	COALESCE(SUM(price_pre_discount), 0) AS sum_price_pre_discount,
	COALESCE(SUM(discount_amount), 0) AS sum_discount_amount,
	COALESCE(SUM(price_post_discount), 0) AS sum_price_post_discount,
	COALESCE(SUM(discount_amount), 0) * 100.0/COALESCE(SUM(price_pre_discount), 0) AS pct_discount_price
FROM
	voucher_redemption
GROUP BY
	coupon_name,
	coupon_code_type,
	coupon_partner_name,
	usage,
	single_or_multi_course,
	course_seat_types,
	coupon_start_date,
	coupon_end_date,
	active_inactive,
	voucher_type,
	discount_type,
	discount_value,
	max_global_applications;

DROP TABLE tmp_credit_uuid;

GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO standard;
GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO analyst;
