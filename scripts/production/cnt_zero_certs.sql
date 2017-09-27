SELECT
	a.course_id,
	b.pacing_type,
	b.catalog_course_title,
	b.end_time,
	SUM(CASE WHEN current_enrollment_mode = 'verified' THEN 1 ELSE 0 END) AS cnt_verified_enrolls,
	SUM(COALESCE(is_certified, 0)) AS cnt_certs
FROM
	d_user_course a
JOIN
	d_course b
ON a.course_id = b.course_id
AND b.end_time BETWEEN '2016-10-01' AND (CURRENT_DATE() - 7)
LEFT JOIN
	d_user_course_certificate c 
ON a.course_id = c.course_id
AND a.user_id = c.user_id
GROUP BY
	a.course_id,
	b.pacing_type,
	b.catalog_course_title,
	b.end_time
HAVING 
	SUM(COALESCE(is_certified, 0)) = 0
	AND SUM(CASE WHEN current_enrollment_mode = 'verified' THEN 1 ELSE 0 END) > 0;

SELECT 
	b.user_id,
	b.user_email,
	max(modified_date) as last_modified
FROM 
	d_user_course_certificate a
JOIN
	d_user b 
ON a.user_id = b.user_id
JOIN
        d_course c
ON a.course_id = c.course_id
AND c.org_id = 'Wharton'

GROUP BY 
        1,2
HAVING 
	SUM(has_passed) = 4