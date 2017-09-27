

SELECT
	*
FROM
(
	SELECT
		'fy17' AS fiscal_year,
		COUNT(1) AS cnt_enrolls,
		COUNT(distinct user_id) AS cnt_unique_users_enrolled,
		SUM(CASE WHEN first_verified_enrollment_time <= '2016-09-05' THEN 1 ELSE 0 END) AS cnt_verifications,
		SUM(CASE WHEN first_verified_enrollment_time <= '2016-09-05' THEN 1 ELSE 0 END) *100.0/count(1) AS vtr,
		COUNT(1)/COUNT(DISTINCT user_id) AS enrolls_per_user
	FROM
		production.d_user_course
	WHERE
		first_enrollment_time BETWEEN '2016-07-01' AND '2016-09-05'

	UNION ALL

	SELECT
		'fy17' AS fiscal_year,
		COUNT(1) AS cnt_enrolls,
		COUNT(distinct user_id) AS cnt_unique_users_enrolled,
		SUM(CASE WHEN first_verified_enrollment_time <= '2017-09-05' THEN 1 ELSE 0 END) AS cnt_verifications,
		SUM(CASE WHEN first_verified_enrollment_time <= '2017-09-05' THEN 1 ELSE 0 END) *100.0/count(1) AS vtr,
		COUNT(1)/COUNT(DISTINCT user_id) AS enrolls_per_user
	FROM
		production.d_user_course
	WHERE
		first_enrollment_time BETWEEN '2017-07-01' AND '2017-09-05'
) a

select * from (
select
'fy17' as fiscal_year,
avg(order_line_item_unit_price)
from finance.f_orderitem_transactions a
join course_master b
on a.order_course_id = b.course_id
and b.is_wl = 0
and a.transaction_date between '2016-07-01' and '2016-09-01'
and order_product_class = 'seat'
and transaction_type = 'sale'

UNION ALL

select
'fy18' as fiscal_year,
avg(order_line_item_unit_price)
from finance.f_orderitem_transactions a
join course_master b
on a.order_course_id = b.course_id
and b.is_wl = 0
and a.transaction_date between '2017-07-01' and '2017-09-01'
and order_product_class = 'seat'
and transaction_type = 'sale'
) a