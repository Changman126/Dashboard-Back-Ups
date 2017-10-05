--Creates a Per Day view of first enrollments, first verifications, and first certificates at the course_id level
--User First Course
DROP TABLE IF EXISTS tmp_user_first_course_enroll;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_user_first_course_enroll ON COMMIT PRESERVE ROWS AS
SELECT
	user_id,
	course_id,
	DATE(first_enrollment_time) AS user_first_course_enrollment_date,
	ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY first_enrollment_time) AS rank
FROM
	production.d_user_course
GROUP BY
	user_id,
	course_id,
	first_enrollment_time;
	
	
--First Course Enrollment by Day
DROP TABLE IF EXISTS tmp_daily_first_enrolls;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_daily_first_enrolls ON COMMIT PRESERVE ROWS AS
SELECT
	user_first_course_enrollment_date,
	course_id,
	COUNT(*) AS cnt_first_enrolls
FROM
	tmp_user_first_course_enroll
WHERE
	rank = 1
GROUP BY
	user_first_course_enrollment_date,
	course_id;
	

--User First Verification
DROP TABLE IF EXISTS tmp_user_first_course_verification;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_user_first_course_verification ON COMMIT PRESERVE ROWS AS
SELECT
	user_id,
	course_id,
	DATE(first_verified_enrollment_time) AS user_first_course_verification_date,
	ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY first_verified_enrollment_time) AS rank
FROM
	production.d_user_course
WHERE
	first_verified_enrollment_time IS NOT NULL
GROUP BY
	user_id,
	course_id,
	first_verified_enrollment_time;
	
	
--Daily First Verifications
DROP TABLE IF EXISTS tmp_daily_first_verifs;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_daily_first_verifs ON COMMIT PRESERVE ROWS AS	
SELECT
	user_first_course_verification_date,
	course_id,
	COUNT(*) AS cnt_first_verifications
FROM
	tmp_user_first_course_verification
WHERE
	rank = 1
GROUP BY
	user_first_course_verification_date,
	course_id;


--User First Completion
DROP TABLE IF EXISTS tmp_user_first_course_cert;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_user_first_course_cert ON COMMIT PRESERVE ROWS AS
SELECT
	user_id,
	course_id,
	DATE(created_date) AS user_first_course_cert_date,
	ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_date) AS rank	
FROM
	production.d_user_course_certificate
WHERE
	is_certified = 1
GROUP BY
	user_id,
	course_id,
	created_date;
	
--Daily First Cert
DROP TABLE IF EXISTS tmp_daily_first_cert;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_daily_first_cert ON COMMIT PRESERVE ROWS AS
SELECT
	user_first_course_cert_date,
	course_id,
	COUNT(*) AS cnt_first_certs
FROM
	tmp_user_first_course_cert
WHERE
	rank = 1
GROUP BY
	user_first_course_cert_date,
	course_id;

	
--Course First Events Table
DROP TABLE IF EXISTS course_first_event;
CREATE TABLE IF NOT EXISTS course_first_event AS
SELECT 
	COALESCE(
		user_first_course_enrollment_date,
		user_first_course_verification_date,
		user_first_course_cert_date
	) AS absolute_date,
	COALESCE(
		enroll.course_id,
		verif.course_id,
		cert.course_id
	) AS course_id,
	cnt_first_enrolls,
	cnt_first_verifications,
	cnt_first_certs
FROM
	tmp_daily_first_enrolls enroll
FULL JOIN
	tmp_daily_first_verifs verif
ON
	user_first_course_enrollment_date = user_first_course_verification_date
AND
	enroll.course_id = verif.course_id
FULL JOIN
	tmp_daily_first_cert cert
ON
	user_first_course_enrollment_date = user_first_course_cert_date
AND
	enroll.course_id = cert.course_id;
	
DROP TABLE IF EXISTS tmp_user_first_course_enroll;
DROP TABLE IF EXISTS tmp_daily_first_enrolls;
DROP TABLE IF EXISTS tmp_user_first_course_verification;
DROP TABLE IF EXISTS tmp_daily_first_verifs;
DROP TABLE IF EXISTS tmp_user_first_course_cert;
DROP TABLE IF EXISTS tmp_daily_first_cert;

GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO standard;
GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO analyst;