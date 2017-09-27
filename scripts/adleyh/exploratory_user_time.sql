
--Course Stats Summary User Table
--Temp Table for enrollments and verifications
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_enrollsverifs ON COMMIT PRESERVE ROWS AS
SELECT
	DATE(first_enrollment_time) AS date,
	user_last_location_country_code AS user_country_code,
	user_gender,
	YEAR(getdate()) - user_year_of_birth AS user_age,
	user_level_of_education AS user_education_level,
	course_id,
	COUNT(1) AS cnt_enrolls,
	COUNT(first_verified_enrollment_time) AS cnt_verifications,
	COUNT(last_unenrollment_time) AS cnt_unenrolls
FROM
	production.d_user_course user_course
LEFT JOIN
	production.d_user u
ON
	user_course.user_id = u.user_id
GROUP BY
	DATE(first_enrollment_time),
	user_country_code,
	user_gender,
	user_age,
	user_education_level,
	course_id;

--Temp Table for enrollments for vtr calculations
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_enrolls_vtr ON COMMIT PRESERVE ROWS AS	
SELECT
	DATE(first_enrollment_time) AS date,
	user_last_location_country_code AS user_country_code,
	user_gender,
	YEAR(getdate()) - user_year_of_birth AS user_age,
	user_level_of_education AS user_education_level,
	user_course.course_id,
	SUM(CASE
			WHEN seat.course_seat_upgrade_deadline IS NULL THEN 1
			WHEN first_enrollment_time <= seat.course_seat_upgrade_deadline THEN 1
			ELSE 0
		END) AS cnt_enrolls_vtr
FROM
	production.d_user_course user_course
LEFT JOIN
	production.d_user u
ON
	user_course.user_id = u.user_id
LEFT JOIN
	production.d_course_seat seat
ON
	user_course.course_id = seat.course_id
AND
	seat.course_seat_type = 'verified'
GROUP BY
	DATE(first_enrollment_time),
	user_country_code,
	user_gender,
	user_age,
	user_education_level,
	user_course.course_id;	
	
--Temp Table for Transactions	
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_transactions ON COMMIT PRESERVE ROWS AS	
SELECT
	DATE(transaction_date) AS date,
	user_last_location_country_code AS user_country_code,
	user_gender,
	YEAR(getdate()) - user_year_of_birth AS user_age,
	user_level_of_education AS user_education_level,
	order_course_id,
	SUM(CASE 
		WHEN order_product_class = 'seat' AND transaction_type = 'sale' THEN 1
		ELSE 0 
	END) AS cnt_paid_enrollments,
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
	finance.f_orderitem_transactions t
LEFT JOIN
	production.d_user u
ON
	LOWER(t.order_username) = LOWER(u.user_username)
WHERE
	order_id IS NOT NULL
AND
	transaction_date IS NOT NULL
GROUP BY
	DATE(transaction_date),
	user_country_code,
	user_gender,
	user_age,
	user_education_level,
	order_course_id;	
	
--Temp Table for certificates	
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_certs ON COMMIT PRESERVE ROWS AS	
SELECT
	DATE(modified_date) AS date,
	user_last_location_country_code AS user_country_code,
	user_gender,
	YEAR(getdate()) - user_year_of_birth AS user_age,
	user_level_of_education AS user_education_level,
	course_id,
	COUNT(*) AS cnt_certificates
FROM
	production.d_user_course_certificate cert
LEFT JOIN
	production.d_user u
ON
	cert.user_id = u.user_id
WHERE
	is_certified = 1
GROUP BY
	DATE(modified_date),
	user_country_code,
	user_gender,
	user_age,
	user_education_level,
	course_id;	

--Temp Table for completions	
DROP TABLE IF EXISTS tmp_completions;	
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_completions ON COMMIT PRESERVE ROWS AS	
SELECT
	DATE(modified_date) AS date,
	user_last_location_country_code AS user_country_code,
	user_gender,
	YEAR(getdate()) - user_year_of_birth AS user_age,
	user_level_of_education AS user_education_level,
	course_id,
	COUNT(*) AS cnt_completions
FROM
	production.d_user_course_certificate cert
LEFT JOIN
	production.d_user u
ON
	cert.user_id = u.user_id
WHERE
	has_passed = 1
GROUP BY
	DATE(modified_date),
	user_country_code,
	user_gender,
	user_age,
	user_education_level,
	course_id;		

--Summary Table created here	
DROP TABLE IF EXISTS ahemphill.course_stats_user_summary_time;
CREATE TABLE IF NOT EXISTS ahemphill.course_stats_user_summary_time AS
SELECT
	COALESCE(
		enrolls_verifs.date,
		vtr.date,
		trans.date,
		cert.date,
		comp.date
	) AS date,
	COALESCE(
		enrolls_verifs.user_country_code,
		vtr.user_country_code,
		trans.user_country_code,
		cert.user_country_code,
		comp.user_country_code
	) AS user_country_code,
	COALESCE(
		enrolls_verifs.user_gender,
		vtr.user_gender,
		trans.user_gender,
		cert.user_gender,
		comp.user_gender
	) AS user_gender,
	COALESCE(
		enrolls_verifs.course_id,
		vtr.course_id,
		trans.order_course_id,
		cert.course_id,
		comp.course_id
	) AS course_id,
	COALESCE(
		enrolls_verifs.user_age,
		vtr.user_age,
		trans.user_age,
		cert.user_age,
		comp.user_age
	) AS user_age,
	COALESCE(
		enrolls_verifs.user_education_level,
		vtr.user_education_level,
		trans.user_education_level,
		cert.user_education_level,
		comp.user_education_level
	) AS user_education_level,
	cnt_enrolls,
	cnt_unenrolls,
	cnt_verifications,
	cnt_enrolls_vtr,
	cnt_paid_enrollments,
	sum_bookings,
	sum_seat_bookings,
	sum_donations_bookings,
	sum_reg_code_bookings,
	cnt_certificates,
	cnt_completions
FROM
	tmp_enrollsverifs enrolls_verifs
FULL JOIN
	tmp_enrolls_vtr vtr
ON
	enrolls_verifs.course_id = vtr.course_id
AND
	enrolls_verifs.user_country_code = vtr.user_country_code
AND
	enrolls_verifs.user_gender = vtr.user_gender
AND
	enrolls_verifs.user_age = vtr.user_age
AND
	enrolls_verifs.user_education_level = vtr.user_education_level
AND
	enrolls_verifs.date = vtr.date
FULL JOIN
	tmp_transactions trans
ON
	enrolls_verifs.course_id = trans.order_course_id
AND
	enrolls_verifs.user_country_code = trans.user_country_code
AND
	enrolls_verifs.user_gender = trans.user_gender
AND
	enrolls_verifs.user_age = trans.user_age
AND
	enrolls_verifs.user_education_level = trans.user_education_level
AND
	enrolls_verifs.date = trans.date
FULL JOIN
	tmp_certs cert
ON
	enrolls_verifs.course_id = cert.course_id
AND
	enrolls_verifs.user_country_code = cert.user_country_code
AND
	enrolls_verifs.user_gender = cert.user_gender
AND
	enrolls_verifs.user_age = cert.user_age
AND
	enrolls_verifs.user_education_level = cert.user_education_level
AND
	enrolls_verifs.date = cert.date
FULL JOIN
	tmp_completions comp
ON
	enrolls_verifs.course_id = comp.course_id
AND
	enrolls_verifs.user_country_code = comp.user_country_code
AND
	enrolls_verifs.user_gender = comp.user_gender
AND
	enrolls_verifs.user_age = comp.user_age
AND
	enrolls_verifs.user_education_level = comp.user_education_level
AND
	enrolls_verifs.date = comp.date;	

DROP TABLE IF EXISTS tmp_enrollsverifs;
DROP TABLE IF EXISTS tmp_enrolls_vtr;
DROP TABLE IF EXISTS tmp_transactions;
DROP TABLE IF EXISTS tmp_certs;	
DROP TABLE IF EXISTS tmp_completions;