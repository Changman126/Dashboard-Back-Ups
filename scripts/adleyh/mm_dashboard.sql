/*
in case we want everything at once...

SELECT
      date(a.first_enrollment_time) AS enroll_date,
      date(a.first_verified_enrollment_time) AS verification_date,
      date(e.modified_date) AS completion_date,
      a.course_id,
      c.catalog_course_title,
      b.program_title,
      d.donation_revenue,
      d.verified_cert_revenue,
      COUNT(a.first_enrollment_time) AS cnt_enrolls,
      COUNT(a.first_verified_enrollment_time) AS cnt_verifs,
      SUM
FROM
production.d_user_course a
JOIN production.d_program_course b
ON a.course_id = b.course_id
AND b.program_type = 'MicroMasters'
JOIN production.d_course c
ON a.course_id = c.course_id
LEFT JOIN 
(
SELECT
date(order_timestamp) AS transaction_date,
order_course_id,
SUM(CASE WHEN order_product_class = 'donation' THEN transaction_amount ELSE 0 END) AS donation_revenue,
SUM(CASE WHEN order_product_class = 'seat' THEN transaction_amount ELSE 0 END) AS verified_cert_revenue
FROM
finance.f_orderitem_transactions d
WHERE
order_product_class IN ('donation','seat')
GROUP BY 1,2
) d
ON date(a.first_verified_enrollment_time) = d.transaction_date
AND a.course_id = d.order_course_id
GROUP BY 1,2,3,4,5,6,7


JOIN
	production.d_course_seat d
ON a.course_id = d.course_id
AND d.course_seat_type = 'verified'
*/

DROP TABLE IF EXISTS ahemphill.micromasters_enrollment_dashboard;
CREATE TABLE IF NOT EXISTS ahemphill.micromasters_enrollment_dashboard AS

SELECT
	DATE(a.first_enrollment_time) AS enrollment_date,
	a.course_id,
	b.program_title,
	c.catalog_course_title,
	COUNT(1) AS cnt_enrolls
FROM
	production.d_user_course a
JOIN 
	production.d_program_course b
ON a.course_id = b.course_id
AND b.program_type = 'MicroMasters'
JOIN 
	production.d_course c
ON a.course_id = c.course_id
GROUP BY
	DATE(a.first_enrollment_time),
	a.course_id,
	b.program_title,
	c.catalog_course_title;

DROP TABLE IF EXISTS ahemphill.micromasters_verifs_dashboard;
CREATE TABLE IF NOT EXISTS ahemphill.micromasters_verifs_dashboard AS

SELECT
	DATE(a.first_verified_enrollment_time) AS verification_date,
	a.course_id,
	b.program_title,
	c.catalog_course_title,
	COUNT(a.first_verified_enrollment_time) AS cnt_verifications
FROM
	production.d_user_course a
JOIN 
	production.d_program_course b
ON a.course_id = b.course_id
AND b.program_type = 'MicroMasters'
JOIN 
	production.d_course c
ON a.course_id = c.course_id
GROUP BY
	DATE(a.first_verified_enrollment_time),
	a.course_id,
	b.program_title,
	c.catalog_course_title;

DROP TABLE IF EXISTS ahemphill.micromasters_completions_dashboard;
CREATE TABLE IF NOT EXISTS ahemphill.micromasters_completions_dashboard AS

SELECT
	DATE(a.modified_date) AS completion_date,
	a.course_id,
	b.program_title,
	c.catalog_course_title,
	CASE WHEN a.certificate_mode = 'verified' THEN a.certificate_mode ELSE 'audit/honor' END AS certificate_mode,
	SUM(has_passed) AS cnt_completions,
	SUM(is_certified) AS cnt_certs_issued
FROM
	production.d_user_course_certificate a
JOIN 
	production.d_program_course b
ON a.course_id = b.course_id
AND b.program_type = 'MicroMasters'
JOIN 
	production.d_course c
ON a.course_id = c.course_id
GROUP BY
	DATE(a.modified_date),
	a.course_id,
	b.program_title,
	c.catalog_course_title,
	5;

DROP TABLE IF EXISTS ahemphill.micromasters_transactions_dashboard;
CREATE TABLE IF NOT EXISTS ahemphill.micromasters_transactions_dashboard AS

SELECT
	DATE(a.transaction_date) AS transaction_date,
	a.order_course_id AS course_id,
	b.program_title,
	c.catalog_course_title,	
	SUM(CASE WHEN a.order_product_class = 'donation' THEN a.transaction_amount ELSE 0 END) AS donation_revenue,
	SUM(CASE WHEN a.order_product_class = 'seat' THEN a.transaction_amount ELSE 0 END) AS verified_cert_revenue
FROM
	finance.f_orderitem_transactions a
JOIN 
	production.d_program_course b
ON a.order_course_id = b.course_id
AND b.program_type = 'MicroMasters'
AND a.order_product_class IN ('donation','seat')
JOIN 
	production.d_course c
ON a.order_course_id = c.course_id
GROUP BY
	DATE(a.transaction_date),
	a.order_course_id,
	b.program_title,
	c.catalog_course_title;

DROP TABLE IF EXISTS ahemphill.micromasters_vtr_dashboard;
CREATE TABLE IF NOT EXISTS ahemphill.micromasters_vtr_dashboard AS

SELECT
	DATE(a.first_enrollment_time) AS enrollment_date,
	a.course_id,
	b.program_title,
	c.catalog_course_title,
	SUM(CASE WHEN a.first_enrollment_time <= d.course_seat_upgrade_deadline THEN 1 ELSE 0 END) AS cnt_enrolls_vtr,
	COALESCE(e.cnt_verifs, 0) AS cnt_verifs
FROM
	production.d_user_course a
JOIN 
	production.d_program_course b
ON a.course_id = b.course_id
AND b.program_type = 'MicroMasters'
JOIN 
	production.d_course c
ON a.course_id = c.course_id
JOIN 
	production.d_course_seat d
ON a.course_id = d.course_id
AND d.course_seat_type = 'verified'
LEFT JOIN
(
	SELECT
		DATE(first_verified_enrollment_time) AS verification_date,
		course_id,
		COUNT(1) AS cnt_verifs
	FROM
		production.d_user_course
	WHERE
		first_verified_enrollment_time IS NOT NULL
	GROUP BY 
		DATE(first_verified_enrollment_time),
		course_id
) e
ON DATE(a.first_enrollment_time) = e.verification_date
AND a.course_id = e.course_id
GROUP BY
	DATE(a.first_enrollment_time),
	a.course_id,
	b.program_title,
	c.catalog_course_title,
	e.cnt_verifs;

DROP TABLE IF EXISTS ahemphill.micromasters_program_stats_dashboard;
CREATE TABLE IF NOT EXISTS ahemphill.micromasters_program_stats_dashboard AS

SELECT
	b.program_title,
	COUNT(1) AS cnt_enrolls,
	COUNT(DISTINCT a.user_id) AS cnt_unique_enrolls,
	c.cnt_verifs,
	c.cnt_unique_verifs,
	d.cnt_completions,
	d.cnt_unique_completions
FROM
	production.d_user_course a
JOIN 
	production.d_program_course b
ON a.course_id = b.course_id
AND b.program_type = 'MicroMasters'
JOIN
(
	SELECT
		b.program_title,
		COUNT(1) AS cnt_verifs,
		COUNT(DISTINCT a.user_id) AS cnt_unique_verifs
	FROM
		production.d_user_course a
	JOIN 
		production.d_program_course b
	ON a.course_id = b.course_id
	AND b.program_type = 'MicroMasters'
	WHERE
		a.first_verified_enrollment_time IS NOT NULL
	GROUP BY
		b.program_title
) c
ON b.program_title = c.program_title
LEFT JOIN
(
	SELECT
		b.program_title,
		COUNT(DISTINCT a.user_id) AS cnt_unique_completions,
		COUNT(1) AS cnt_completions
	FROM
		production.d_user_course_certificate a
	JOIN 
		production.d_program_course b
	ON a.course_id = b.course_id
	AND b.program_type = 'MicroMasters'
	WHERE
		a.has_passed = 1
	GROUP BY
		b.program_title
) d
ON b.program_title = d.program_title
GROUP BY
	b.program_title,
	c.cnt_verifs,
	c.cnt_unique_verifs,
	d.cnt_completions,
	d.cnt_unique_completions;