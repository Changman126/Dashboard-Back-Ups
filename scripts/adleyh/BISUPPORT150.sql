CREATE TABLE ahemphill.bisupport_150 (user_email varchar(555), group varchar(555));

COPY ahemphill.bisupport_150 FROM LOCAL '/Users/adleyhemphill/Downloads/BISUPPORT_150.csv' WITH DELIMITER ',';


SELECT
	a.user_email,
	a.user_group,
	b.user_id,
	c.course_id,
	c.current_enrollment_mode,
	CASE WHEN d.user_id IS NULL THEN 'inactive' ELSE 'active' END AS is_active
FROM 
	ahemphill.bisupport_150 a 
JOIN 
	production.d_user b
ON 
	a.user_email = b.user_email
LEFT JOIN 
	production.d_user_course c
ON 
	b.user_id = c.user_id
AND 
	c.course_id = 'course-v1:RITx+CYBER501x+1T2017'
LEFT JOIN 
(
	SELECT 
		user_id, 
		course_id
	FROM 
		production.f_user_activity
	WHERE 
		course_id = 'course-v1:RITx+CYBER501x+1T2017'
	GROUP BY 
		1,2
) d 
ON 
	c.user_id = d.user_id
AND 
	c.course_id = d.course_id
