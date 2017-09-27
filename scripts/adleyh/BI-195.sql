DROP TABLE IF EXISTS ahemphill.refunds_by_enroll_time_course_end;
CREATE TABLE ahemphill.refunds_by_enroll_time_course_end AS
SELECT
	a.course_id,
	b.course_partner,
	CASE 
		WHEN DATEDIFF('day', DATE(first_enrollment_time), DATE(course_end_date)) BETWEEN 0 AND 6 THEN '1_week'
		WHEN DATEDIFF('day', DATE(first_enrollment_time), DATE(course_end_date)) BETWEEN 7 AND 13 THEN '2_weeks'
		WHEN DATEDIFF('day', DATE(first_enrollment_time), DATE(course_end_date)) BETWEEN 14 AND 20 THEN '3_weeks'
		ELSE '>3_weeks'
	END AS weeks_course_end_date,
	CASE 
		WHEN DATEDIFF('day', DATE(first_enrollment_time), DATE(course_verification_end_date)) BETWEEN 0 AND 6 THEN '1_week'
		WHEN DATEDIFF('day', DATE(first_enrollment_time), DATE(course_verification_end_date)) BETWEEN 7 AND 13 THEN '2_weeks'
		WHEN DATEDIFF('day', DATE(first_enrollment_time), DATE(course_verification_end_date)) BETWEEN 14 AND 20 THEN '3_weeks'
		ELSE '>3_weeks'
	END AS weeks_course_verificaiton_end_date,
	CASE 
		WHEN DATEDIFF('day', DATE(first_enrollment_time), DATE(course_enrollment_end_date)) BETWEEN 0 AND 6 THEN '1_week'
		WHEN DATEDIFF('day', DATE(first_enrollment_time), DATE(course_enrollment_end_date)) BETWEEN 7 AND 13 THEN '2_weeks'
		WHEN DATEDIFF('day', DATE(first_enrollment_time), DATE(course_enrollment_end_date)) BETWEEN 14 AND 20 THEN '3_weeks'
		ELSE '>3_weeks'
	END AS weeks_course_enrollment_end_date,
	DATEDIFF('day', DATE(first_enrollment_time), DATE(course_verification_end_date)) AS days_from_course_end,
	SUM(CASE WHEN current_enrollment_mode NOT IN ('verified', 'no-id-professional', 'professional', 'credit') THEN 1 ELSE 0 END) AS cnt_refunds,
	COUNT(1) AS cnt_verifications
FROM 
	production.d_user_course a
JOIN 
	business_intelligence.course_master b
ON 
	a.course_id = b.course_id
AND 
	first_verified_enrollment_time IS NOT NULL
AND 
	DATE(first_enrollment_time) <= DATE(first_verified_enrollment_time)
AND 
	pacing_type = 'self_paced'
GROUP BY 1,2,3,4,5,6;

-- select
-- 	CASE
-- 		--WHEN transaction_date BETWEEN '2011-07-01' AND '2012-06-30' THEN 2012
-- 		--WHEN transaction_date BETWEEN '2012-07-01' AND '2013-06-30' THEN 2013 
-- 		--WHEN transaction_date BETWEEN '2013-07-01' AND '2014-06-30' THEN 2014 
-- 		WHEN transaction_date BETWEEN '2014-07-01' AND '2015-06-30' THEN 2015 
-- 		WHEN transaction_date BETWEEN '2015-07-01' AND '2016-06-30' THEN 2016 
-- 		WHEN transaction_date BETWEEN '2016-07-01' AND '2017-06-30' THEN 2017 
-- 	END AS fiscal_year,
-- SUM(CASE WHEN transaction_type = 'sale' THEN 1 ELSE 0 END) AS cnt_sales,
-- SUM(CASE WHEN transaction_type = 'refund' THEN 1 ELSE 0 END) AS cnt_refunds,
-- SUM(CASE WHEN transaction_type = 'refund' THEN 1 ELSE 0 END)*100.0/SUM(CASE WHEN transaction_type = 'sale' THEN 1 ELSE 0 END) AS refund_pct
-- from finance.f_orderitem_transactions
-- where transaction_date is not null
-- AND transaction_date >= '2014-07-01'
-- AND order_course_id is not null
-- GROUP BY 1