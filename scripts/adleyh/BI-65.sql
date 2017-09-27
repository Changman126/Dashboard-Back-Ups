DROP TABLE IF EXISTS ahemphill.voucher_redemption_user_level;
CREATE TABLE ahemphill.voucher_redemption_user_level AS

SELECT 
	a.user_id,
	b.user_email,
	a.coupon_code_type,
	a.voucher_code,
	a.coupon_name,
	a.date_voucher_redeemed,
	a.price_pre_discount,
	a.discount_amount,
	a.price_post_discount,
	a.course_id,
	b.user_last_location_country_code AS learner_country,
	b.user_level_of_education AS learner_education,
	b.user_gender AS learner_gender,
	2016- b.user_year_of_birth AS learner_age
	
FROM 
	ahemphill.voucher_redemption_tmp a
JOIN
	d_user b
ON a.user_id = b.user_id
where 
	a.coupon_code_type like '%Financial%';

DROP TABLE IF EXISTS ahemphill.voucher_redemption_user_level_financial;
CREATE TABLE ahemphill.voucher_redemption_user_level_financial AS

select
user_id,
user_email,
count(distinct a.course_id) AS vouchers_redeemed,
count(distinct b.order_course_id) AS prior_courses_purchased,
count(distinct c.order_course_id) AS future_courses_purchased
from ahemphill.voucher_redemption_user_level a
left join finance.f_orderitem_transactions b
on a.user_email = b.order_user_email
AND date(b.transaction_date) < a.date_voucher_redeemed
AND b.order_product_class = 'seat'
AND b.order_refunded_amount = 0.00
left join finance.f_orderitem_transactions c
on a.user_email = c.order_user_email
AND date(c.transaction_date) > a.date_voucher_redeemed
AND c.order_product_class = 'seat'
AND c.order_refunded_amount = 0.00
group by 1,2

DROP TABLE IF EXISTS ahemphill.voucher_redemption_user_level_completions;
CREATE TABLE ahemphill.voucher_redemption_user_level_financial AS

select
a.user_id,
count(distinct a.course_id) AS vouchers_redeemed,
count(distinct b.course_id) AS prior_courses_completed,
count(distinct c.course_id) AS future_courses_purchased
from ahemphill.voucher_redemption_user_level a
left join d_user_course_certificate b
on a.user_id = b.user_id
AND b.modified_date < a.date_voucher_redeemed
AND b.has_passed = 1
left join d_user_course_certificate c
on a.user_id = c.user_id
AND c.modified_date > a.date_voucher_redeemed
AND c.has_passed = 1
GROUP BY 1