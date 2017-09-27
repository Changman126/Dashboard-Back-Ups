DROP TABLE IF EXISTS ahemphill.mit_pe_edx_users;
CREATE TABLE IF NOT EXISTS ahemphill.mit_pe_edx_users AS

SELECT
	DISTINCT a.user_id
FROM
	production.d_user_course a
JOIN
	business_intelligence.course_master b
ON
	a.course_id = b.course_id
AND
	b.course_partner = 'MITProfessionalX'
JOIN
(
	SELECT
		DISTINCT a.user_id
	FROM
		production.d_user_course a
	JOIN
		business_intelligence.course_master b
	ON
		a.course_id = b.course_id
	AND
		b.is_wl = 0
) c
ON 
	a.user_id = c.user_id;

DROP TABLE IF EXISTS ahemphill.tmp_mit_pe_edx_stats;
CREATE TABLE IF NOT EXISTS ahemphill.tmp_mit_pe_edx_stats AS

SELECT
	a.user_id,
	a.course_id,
	a.current_enrollment_mode,
	a.first_enrollment_time,
	c.is_wl,
	c.course_end_date,
	c.pacing_type,
	RANK() OVER (PARTITION BY a.user_id ORDER BY a.first_enrollment_time ASC) as enrollment_order
FROM
	production.d_user_course a
JOIN
	ahemphill.mit_pe_edx_users b
ON
	a.user_id = b.user_id
JOIN
	business_intelligence.course_master c
ON
	a.course_id = c.course_id;

DROP TABLE IF EXISTS ahemphill.mit_pe_edx_stats;
CREATE TABLE IF NOT EXISTS ahemphill.mit_pe_edx_stats AS

SELECT
	a.*,
	CASE WHEN acquisition_source = 1 THEN 'MITPE' ELSE 'edX' END AS acquisition_source
FROM
	ahemphill.tmp_mit_pe_edx_stats a
JOIN
(
	SELECT 
		user_id, 
		MAX(is_wl) AS acquisition_source
	FROM 
		ahemphill.tmp_mit_pe_edx_stats
	WHERE 
		enrollment_order = 1
	GROUP BY
		1
) b
ON a.user_id = b.user_id
;


SELECT
	current_enrollment_mode,
	acquisition_source,
	count(1)
FROM
	ahemphill.mit_pe_edx_stats a
WHERE
	a.is_wl = 0
GROUP BY 
	1,2


SELECT
	acquisition_source,
	has_passed,
	count(1)
from ahemphill.mit_pe_edx_stats a
join production.d_user_course_certificate b
on a.course_id = b.course_id
and a.user_id = b.user_id
and a.pacing_type = 'instructor_paced'
and a.current_enrollment_mode NOT IN ('honor','audit')
AND a.is_wl = 0
AND course_end_date <= CURRENT_DATE()
group by 1,2


SELECT
acquisition_source,
age,
user_level_of_education,
user_gender,
user_last_location_country_code,
COUNT(1)
FROM
(
select
distinct
a.user_id,
acquisition_source,
2017-user_year_of_birth AS age,
user_level_of_education,
user_gender,
user_last_location_country_code
from ahemphill.mit_pe_edx_stats a 
join production.d_user b
on a.user_id = b.user_id
) a
group by 1,2,3,4,5

