CREATE TABLE ahemphill.course_numbers_FY17 AS
SELECT
	course_number,
	COUNT(*)
FROM
	business_intelligence.course_master a
JOIN
	business_intelligence.course_stats_summary b
ON
	a.course_id = b.course_id
AND
	b.sum_enrolls > 1000
AND
	course_start_date >= '2016-07-01'
AND	
	course_end_date <= CURRENT_DATE()
GROUP BY
	course_number
HAVING
	COUNT(*)>1;	
	
SELECT
	course_type,
	AVG(vtr),
	AVG(sum_enrolls) AS avg_enrolls,
	AVG(sum_verifications) AS avg_verifications,
	AVG(sum_bookings) AS avg_bookings
FROM
	(
	SELECT
		a.course_id,
		course_partner,
		is_WL,
		course_number,
		course_run_number,
	    RANK() OVER (PARTITION BY course_number ORDER BY course_start_date) AS course_run_number_FY17,
	    CASE
	    	WHEN RANK() OVER (PARTITION BY course_number ORDER BY course_start_date) = 1 THEN 'First Run'
	    	ELSE 'Rerun'
	    END AS course_type,
		sum_enrolls,
		sum_enrolls_vtr,
		sum_verifications,
		sum_bookings,
	    vtr,
	    course_start_date,
	    course_name
	FROM
		business_intelligence.course_master a
	JOIN
		business_intelligence.course_stats_summary b
	ON
		a.course_id = b.course_id
	AND
		course_start_date >= '2016-07-01'
	AND
		course_end_date <= CURRENT_DATE()
	AND 
		is_WL = 0
	AND
		course_partner != 'Microsoft'
	AND
		course_name NOT LIKE '%Supply%'
	WHERE
		course_number IN 
		(
			SELECT 
				course_number 
			FROM 
				ahemphill.course_numbers_FY17
		)
) a 
GROUP BY
	1