--Scripts for Summary Tables to pull enrollments, verifications, vtr, and bookings at the course run level, program level, partner level, and user level
--Course stats summary table
DROP TABLE IF EXISTS course_stats_summary;
CREATE TABLE IF NOT EXISTS course_stats_summary AS
SELECT
	COALESCE(
		enrollverif.course_id,
		rev.order_course_id
	) AS course_id,
	enrollverif.sum_enrolls,
	enrollverif.sum_unenrolls,
	enrollverif.sum_verifications,
	enroll_vtr.sum_enrolls_vtr,
	enrollverif.sum_verifications/NULLIF(enroll_vtr.sum_enrolls_vtr,0) AS vtr,
	enroll_vtr.course_seat_price * (enrollverif.sum_verifications/NULLIF(enroll_vtr.sum_enrolls_vtr,0)) AS bookings_per_enroll,
	rev.cnt_paid_enrollments,
	rev.sum_bookings,
	rev.sum_seat_bookings,
	rev.sum_donations_bookings,
	rev.sum_reg_code_bookings,
	comp.sum_completions,
	cert.sum_certificates
FROM
	(
		SELECT
			course_id,
			COUNT(1) AS sum_enrolls,
			COUNT(first_verified_enrollment_time) AS sum_verifications,
			COUNT(last_unenrollment_time) AS sum_unenrolls
		FROM
			production.d_user_course c
		GROUP BY
			course_id	
	) enrollverif
LEFT JOIN
	(
		SELECT	
			c.course_id,
			s.course_seat_price,
			SUM(CASE 
					WHEN s.course_seat_upgrade_deadline IS NULL THEN 1
					WHEN c.first_enrollment_time <= s.course_seat_upgrade_deadline THEN 1 
					ELSE 0 
				END) AS sum_enrolls_vtr
		FROM
			production.d_user_course c
		LEFT JOIN
			production.d_course_seat s 
		ON 
			c.course_id = s.course_id
		AND
			s.course_seat_type = 'verified'
		GROUP BY
			c.course_id,
			s.course_seat_price
	) enroll_vtr 
ON
	enrollverif.course_id = enroll_vtr.course_id
LEFT JOIN
	(
		SELECT
			course_id,
			COUNT(*) AS sum_completions
		FROM
			business_intelligence.course_completion_user
		WHERE
			passed_timestamp IS NOT NULL
		GROUP BY
			course_id	
	) comp
ON
	enrollverif.course_id = comp.course_id
LEFT JOIN
	(
		SELECT
			cert.course_id,
			COUNT(*) AS sum_certificates
		FROM
			production.d_user_course_certificate cert
		JOIN
			production.d_user_course user_course
		ON
			cert.user_id = user_course.user_id
		AND
			cert.course_id = user_course.course_id
		AND
			user_course.current_enrollment_mode NOT IN ('honor', 'audit')
		AND
			cert.is_certified = 1
		GROUP BY
			cert.course_id
	) cert
ON
	enrollverif.course_id = cert.course_id	
FULL JOIN
	(
		SELECT
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
			finance.f_orderitem_transactions
		WHERE
			order_id IS NOT NULL
		AND
			transaction_date IS NOT NULL
		GROUP BY
			order_course_id	
	) rev
ON
	enrollverif.course_id = rev.order_course_id;


--Program Stats Summary Table
DROP TABLE IF EXISTS program_stats_summary;
CREATE TABLE IF NOT EXISTS program_stats_summary AS
SELECT
	prog.program_type,
	prog.program_title,
	prog.org_id,
	SUM(sum_enrolls) AS sum_enrolls,
	SUM(sum_unenrolls) AS sum_unenrolls,
	SUM(sum_verifications) AS sum_verifications,
	SUM(sum_enrolls_vtr) AS sum_enrolls_vtr,
	SUM(sum_verifications)/SUM(sum_enrolls_vtr) AS sum_vtr,
	AVG(bookings_per_enroll) AS avg_bookings_per_enroll,
	SUM(cnt_paid_enrollments) AS sum_paid_enrollments,
	SUM(sum_bookings) AS sum_bookings,
	SUM(sum_seat_bookings) AS sum_seat_bookings,
	SUM(sum_donations_bookings) AS sum_donations_bookings,
	SUM(sum_reg_code_bookings) AS sum_reg_code_bookings,
	SUM(sum_completions) AS sum_completions,
	SUM(sum_certificates) AS sum_certificates
FROM
	production.d_program_course prog
LEFT JOIN
	course_stats_summary agg
ON
	prog.course_id = agg.course_id
GROUP BY
	prog.program_type,
	prog.program_title,
	prog.org_id;


--Program Summary Table for Overlapping Enrollments within each program
DROP TABLE IF EXISTS program_enrollment_overlap;
CREATE TABLE IF NOT EXISTS program_enrollment_overlap AS
SELECT
	program_title,
	cnt_courses_in_program,
	COUNT(1) AS cnt_enrolls_courses,
	SUM(CASE 
			WHEN cnt_enrolled_course_in_program = cnt_courses_in_program THEN 1 
			ELSE 0 
		END) AS cnt_enrolled_all,
	SUM(CASE 
			WHEN cnt_enrolled_course_in_program = 1 THEN 1 
			ELSE 0 
		END) AS cnt_enrolled_one,
	SUM(CASE 
			WHEN cnt_enrolled_course_in_program = 2 THEN 1 
			ELSE 0 
		END) AS cnt_enrolled_two,
	SUM(CASE 
			WHEN cnt_enrolled_course_in_program = 3 THEN 1 
			ELSE 0 
		END) AS cnt_enrolled_three,
	SUM(CASE
			WHEN cnt_enrolled_course_in_program = 4 THEN 1
			ELSE 0
		END) AS cnt_enrolled_four,
	SUM(CASE
			WHEN cnt_enrolled_course_in_program = 5 THEN 1
			ELSE 0
		END) AS cnt_enrolled_five
FROM
	(
		SELECT
			user_course.user_id,
			program_course.program_title,
			program_count.cnt_courses_in_program,
			COUNT(DISTINCT program_course.catalog_course) AS cnt_enrolled_course_in_program
		FROM 
			production.d_user_course user_course
		JOIN 
			production.d_program_course program_course
		ON 
			user_course.course_id = program_course.course_id
		JOIN
			(
				SELECT 
					program_title, 
					COUNT(DISTINCT catalog_course) AS cnt_courses_in_program
				FROM 
					production.d_program_course 
				GROUP BY
					program_title
			) program_count
		ON 
			program_course.program_title = program_count.program_title
		GROUP BY
			user_course.user_id,
			program_course.program_title,
			program_count.cnt_courses_in_program
	) program_stats
GROUP BY
	program_title,
	cnt_courses_in_program;		


--Partner Stats Summary Table
DROP TABLE IF EXISTS partner_stats_summary;
CREATE TABLE IF NOT EXISTS partner_stats_summary AS
SELECT 
	catalog.org_id,
	COUNT(agg.course_id) AS course_run_count,
	COUNT(DISTINCT catalog_course) AS course_count,
	SUM(sum_enrolls) AS sum_partner_enrolls,
	SUM(sum_unenrolls) AS sum_partner_unenrolls,
	SUM(sum_verifications) AS sum_partner_verifications,
	SUM(sum_enrolls_vtr) AS sum_partner_enrolls_vtr,
	SUM(sum_verifications)/SUM(sum_enrolls_vtr) AS sum_partner_vtr,
	AVG(bookings_per_enroll) AS avg_bookings_per_enroll,
	SUM(cnt_paid_enrollments) AS sum_partner_paid_enrollments,
	SUM(sum_bookings) AS sum_partner_bookings,
	SUM(sum_seat_bookings) AS sum_partner_seat_bookings,
	SUM(sum_donations_bookings) AS sum_partner_donations_bookings,
	SUM(sum_reg_code_bookings) AS sum_partner_reg_code_bookings,
	SUM(sum_completions) AS sum_partner_completions,
	SUM(sum_certificates) AS sum_partner_certificates
FROM
	course_stats_summary agg
LEFT JOIN
	production.d_course catalog
ON
	agg.course_id = catalog.course_id
GROUP BY
	catalog.org_id;	


--Course Stats Summary User Table
--Temp Table for enrollments and verifications
DROP TABLE IF EXISTS tmp_enrollsverifs;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_enrollsverifs ON COMMIT PRESERVE ROWS AS
SELECT
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
	user_country_code,
	user_gender,
	user_age,
	user_education_level,
	course_id;

--Temp Table for enrollments for vtr calculations
DROP TABLE IF EXISTS tmp_enrolls_vtr;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_enrolls_vtr ON COMMIT PRESERVE ROWS AS	
SELECT
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
	user_country_code,
	user_gender,
	user_age,
	user_education_level,
	user_course.course_id;	
	
--Temp Table for Transactions	
DROP TABLE IF EXISTS tmp_transactions;	
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_transactions ON COMMIT PRESERVE ROWS AS	
SELECT
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
	user_country_code,
	user_gender,
	user_age,
	user_education_level,
	order_course_id;	
	
--Temp Table for certificates	
DROP TABLE IF EXISTS tmp_certs;	
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_certs ON COMMIT PRESERVE ROWS AS	
SELECT
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
	user_country_code,
	user_gender,
	user_age,
	user_education_level,
	course_id;	

--Temp Table for completions	
DROP TABLE IF EXISTS tmp_completions;	
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_completions ON COMMIT PRESERVE ROWS AS	
SELECT
	user_last_location_country_code AS user_country_code,
	user_gender,
	YEAR(getdate()) - user_year_of_birth AS user_age,
	user_level_of_education AS user_education_level,
	course_id,
	COUNT(*) AS cnt_completions
FROM
	business_intelligence.course_completion_user cert
LEFT JOIN
	production.d_user u
ON
	cert.user_id = u.user_id
WHERE
	passed_timestamp IS NOT NULL
GROUP BY
	user_country_code,
	user_gender,
	user_age,
	user_education_level,
	course_id;		

--Summary Table created here	
DROP TABLE IF EXISTS course_stats_user_summary;
CREATE TABLE IF NOT EXISTS course_stats_user_summary AS
SELECT
	COALESCE(
		enrolls_verifs.user_country_code,
		vtr.user_country_code,
		trans.user_country_code,
		cert.user_country_code,
		comp.user_country_code
	) AS user_country_code,
	CASE
		WHEN spanish.country_name IS NOT NULL THEN 'spanish_language_country'
		ELSE 'non_spanish_language_country'
	END AS user_spanish_language_country,
	CASE
		WHEN COALESCE(
		enrolls_verifs.user_gender,
		vtr.user_gender,
		trans.user_gender,
		cert.user_gender,
		comp.user_gender
	) IN ('m', 'f') THEN
		COALESCE(
		enrolls_verifs.user_gender,
		vtr.user_gender,
		trans.user_gender,
		cert.user_gender,
		comp.user_gender
	)
		ELSE
			'undefined'
	END AS user_gender,
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
LEFT JOIN
	business_intelligence.spanish_language_countries spanish
ON
	COALESCE(
		enrolls_verifs.user_country_code,
		vtr.user_country_code,
		trans.user_country_code,
		cert.user_country_code,
		comp.user_country_code
	) = spanish.user_last_location_country_code;	

DROP TABLE IF EXISTS tmp_enrollsverifs;
DROP TABLE IF EXISTS tmp_enrolls_vtr;
DROP TABLE IF EXISTS tmp_transactions;
DROP TABLE IF EXISTS tmp_certs;	
DROP TABLE IF EXISTS tmp_completions;

GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO standard;
GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO analyst;