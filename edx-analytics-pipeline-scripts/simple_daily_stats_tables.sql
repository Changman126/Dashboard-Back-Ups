--Simple Daily Tables to show Enrollments, Verifications, VTR, and Bookings over time
--Enrollments by Day
DROP TABLE IF EXISTS tmp_daily_enrolls;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_daily_enrolls ON COMMIT PRESERVE ROWS AS
SELECT
	DATE(first_enrollment_time) AS enroll_date,
	COUNT(*) AS cnt_enrolls
FROM
	production.d_user_course
GROUP BY
	enroll_date;

--Verifications by Day
DROP TABLE IF EXISTS tmp_daily_verifications;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_daily_verifications ON COMMIT PRESERVE ROWS AS
SELECT
	DATE(first_verified_enrollment_time) AS verification_date,
	COUNT(first_verified_enrollment_time) AS cnt_verifications
FROM
	production.d_user_course
WHERE
	first_verified_enrollment_time IS NOT NULL
GROUP BY
	verification_date;	
	
--Registrations by Day	
DROP TABLE IF EXISTS tmp_daily_reg;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_daily_reg ON COMMIT PRESERVE ROWS AS
SELECT
	DATE(user_account_creation_time) AS reg_date,
	COUNT(*) AS cnt_registrations
FROM
	production.d_user
GROUP BY
	reg_date;

--Enrollments for Verified Take Rate by Day; Excludes all Enrollments after a Verification Deadline
DROP TABLE IF EXISTS tmp_daily_enrolls_vtr;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_daily_enrolls_vtr ON COMMIT PRESERVE ROWS AS
SELECT	
	DATE(first_enrollment_time) AS enroll_vtr_date,
	SUM(CASE 
			WHEN s.course_seat_upgrade_deadline IS NULL THEN 1
			WHEN c.first_enrollment_time <= s.course_seat_upgrade_deadline THEN 1 
			ELSE 0 
		END) AS cnt_enrolls_vtr
FROM
	production.d_user_course c
LEFT JOIN
	production.d_course_seat s 
ON 
	c.course_id = s.course_id
AND
	s.course_seat_type = 'verified'
GROUP BY
	enroll_vtr_date;

--Daily Unenrollments	
DROP TABLE IF EXISTS tmp_daily_unenrolls;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_daily_unenrolls ON COMMIT PRESERVE ROWS AS
SELECT  
	DATE(last_unenrollment_time) AS unenroll_date,
	COUNT(last_unenrollment_time) AS cnt_unenrolls
FROM 
	production.d_user_course
WHERE
	last_unenrollment_time IS NOT NULL
GROUP BY
	unenroll_date;	
	
--Daily Verified Take Rate and some other weekly calculations
DROP TABLE IF EXISTS tmp_daily_vtr;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_daily_vtr ON COMMIT PRESERVE ROWS AS
SELECT
	COALESCE(
		verifications.verification_date,
		enrolls.enroll_vtr_date
	) AS vtr_date,
	cnt_verifications,
	cnt_enrolls_vtr,
	cnt_unenrolls,
	SUM(cnt_verifications) OVER (ORDER BY verifications.verification_date) AS cum_sum_verifications,
	SUM(cnt_enrolls_vtr) OVER (ORDER BY verifications.verification_date) AS cum_sum_enrolls_vtr,
	cnt_verifications/cnt_enrolls_vtr AS daily_vtr,
	SUM(cnt_verifications) OVER (ORDER BY verifications.verification_date)/SUM(cnt_enrolls_vtr) OVER (ORDER BY verifications.verification_date) AS cum_sum_vtr,
	AVG(cnt_verifications) OVER (ORDER BY verifications.verification_date RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW) AS weekly_avg_verifications,
	AVG(cnt_enrolls_vtr) OVER (ORDER BY verifications.verification_date RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW) AS weekly_avg_enrolls_vtr,
	AVG(cnt_verifications) OVER (ORDER BY verifications.verification_date RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW)/AVG(cnt_enrolls_vtr) OVER (ORDER BY verifications.verification_date RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW) AS weekly_avg_vtr
FROM
	tmp_daily_verifications verifications
FULL JOIN
	tmp_daily_enrolls_vtr enrolls
ON 
	verifications.verification_date = enrolls.enroll_vtr_date
LEFT JOIN
	tmp_daily_unenrolls unenrolls
ON
	verifications.verification_date = unenrolls.unenroll_date;
	
--Daily Bookings
DROP TABLE IF EXISTS tmp_daily_bookings;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_daily_bookings ON COMMIT PRESERVE ROWS AS
SELECT
	DATE(transaction_date) AS transaction_date,
	SUM(transaction_amount_per_item) AS sum_bookings,
	SUM(CASE 
			WHEN order_product_class = 'seat' THEN transaction_amount_per_item 
			ELSE 0 
		END) AS sum_seat_bookings,
	SUM(CASE
			WHEN order_product_class = 'donation' THEN transaction_amount_per_item
			ELSE 0
		END) AS sum_donations_bookings,
	SUM(CASE
			WHEN order_product_class = 'reg-code' THEN transaction_amount_per_item
			ELSE 0
		END) AS sum_reg_code_bookings
FROM
	finance.f_orderitem_transactions
WHERE
	order_id IS NOT NULL
AND
	transaction_date IS NOT NULL
GROUP BY
	transaction_date;
	
--Summary of Registrations, Enrollments, Enrollments for VTR, and Verifications
DROP TABLE IF EXISTS daily_stats;
CREATE TABLE IF NOT EXISTS daily_stats AS		
SELECT
	reg_date AS date,
	cnt_registrations,
	cnt_enrolls,
	cnt_enrolls_vtr,
	cnt_verifications,
	cnt_unenrolls,
	SUM(cnt_registrations) OVER (ORDER BY reg_date) AS cum_sum_registrations,
	SUM(cnt_enrolls) OVER (ORDER BY reg_date) AS cum_sum_enrolls,
	SUM(cnt_unenrolls) OVER (ORDER BY reg_date) AS cum_sum_unenrolls,
	cum_sum_enrolls_vtr,
	cum_sum_verifications,
	vtr.daily_vtr,
	vtr.cum_sum_vtr,
	vtr.weekly_avg_verifications,
	vtr.weekly_avg_enrolls_vtr,
	AVG(cnt_registrations) OVER (ORDER BY reg_date RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW) AS weekly_avg_registrations,
	AVG(cnt_enrolls) OVER (ORDER BY reg_date RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW) AS weekly_avg_enrolls,
	AVG(cnt_unenrolls) OVER (ORDER BY reg_date RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW) AS weekly_avg_unenrolls,	
	vtr.weekly_avg_vtr,
	sum_bookings,
	sum_seat_bookings,
	sum_donations_bookings,
	sum_reg_code_bookings,
	SUM(sum_bookings) OVER (ORDER BY reg_date) AS cum_sum_bookings,
	SUM(sum_seat_bookings) OVER (ORDER BY reg_date) AS cum_sum_seat_bookings,
	SUM(sum_donations_bookings) OVER (ORDER BY reg_date) AS cum_sum_donations_bookings,
	SUM(sum_reg_code_bookings) OVER (ORDER BY reg_date) AS cum_sum_reg_code_bookings,
	AVG(sum_bookings) OVER (ORDER BY reg_date RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW) AS weekly_avg_bookings,
	AVG(sum_seat_bookings) OVER (ORDER BY reg_date RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW) AS weekly_avg_seat_bookings,
	AVG(sum_donations_bookings) OVER (ORDER BY reg_date RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW) AS weekly_avg_donations_bookings,
	AVG(sum_reg_code_bookings) OVER (ORDER BY reg_date RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW) AS weekly_avg_reg_code_bookings
FROM
	tmp_daily_reg reg
FULL JOIN
	tmp_daily_enrolls enroll
ON
	reg.reg_date = enroll.enroll_date
LEFT JOIN
	tmp_daily_vtr vtr
ON
	reg.reg_date = vtr.vtr_date
LEFT JOIN
	tmp_daily_bookings rev
ON
	reg.reg_date = rev.transaction_date;

DROP TABLE IF EXISTS tmp_daily_enrolls;
DROP TABLE IF EXISTS tmp_daily_verifications;
DROP TABLE IF EXISTS tmp_daily_reg;
DROP TABLE IF EXISTS tmp_daily_unenrolls;
DROP TABLE IF EXISTS tmp_daily_enrolls_vtr;
DROP TABLE IF EXISTS tmp_daily_vtr;
DROP TABLE IF EXISTS tmp_daily_bookings;

GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO standard;
GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO analyst;