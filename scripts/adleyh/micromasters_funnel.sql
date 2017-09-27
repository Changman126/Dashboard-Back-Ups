DROP TABLE IF EXISTS ahemphill.utm_course_enroll_client_side;
CREATE TABLE ahemphill.utm_course_enroll_client_side AS
SELECT DISTINCT
  FIRST_VALUE(CAST(e.timestamp AS TIMESTAMPTZ)) OVER (PARTITION BY e.user_id, e.course_id ORDER BY CAST(e.timestamp AS TIMESTAMPTZ) ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS timestamp,
  FIRST_VALUE(CASE WHEN POSITION('.edx.org' IN host) > 0 THEN 'edx.org' ELSE host END) OVER (PARTITION BY e.user_id, e.course_id ORDER BY CAST(e.timestamp AS TIMESTAMPTZ) ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS domain,
  u.user_id,
  e.label AS course_id,
  CAST(e.timestamp AS DATE) AS date,
  FIRST_VALUE(e.mode) OVER (PARTITION BY e.user_id, e.course_id ORDER BY CAST(e.timestamp AS TIMESTAMPTZ) ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS mode,
  LAST_VALUE(CAST(e.timestamp AS TIMESTAMPTZ)) OVER (PARTITION BY e.user_id, e.course_id ORDER BY CAST(e.timestamp AS TIMESTAMPTZ) ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_enrollment_timestamp
FROM experimental_events_run14.event_records e
JOIN ahemphill.identify u
ON u.anonymous_id = e.anonymous_id
WHERE
  e.event_type IN
  ('edx.bi.user.course-details.enroll.header',
'edx.bi.user.course-details.enroll.main',
'edx.bi.user.xseries-details.enroll.discovery-card',
'edx.bi.user.course-details.enroll.discovery-card'
)
  AND e.project = 'hqawk62tyf'
;

DROP TABLE IF EXISTS ahemphill.homepage_funnel;
CREATE TABLE ahemphill.homepage_funnel AS
SELECT
	a.user_id,
	a.course_id,
	a.last_enrollment_timestamp,
	a.date,
	c.path,
	CAST(c.timestamp AS TIMESTAMP) AS page_view_timestamp,
	RANK() OVER (PARTITION BY a.user_id, a.course_id ORDER BY CAST(c.timestamp AS TIMESTAMP) DESC) AS page_order
FROM
	ahemphill.utm_course_enroll_client_side a
JOIN
	experimental_events_run14.event_records c
ON
	CAST(a.user_id AS VARCHAR) = CAST(c.user_id AS VARCHAR)
	AND c.event_type = 'page'
	AND c.channel = 'client'
	AND CAST(c.timestamp AS TIMESTAMP) < a.last_enrollment_timestamp
	AND CAST(c.timestamp AS DATE) = CAST(a.last_enrollment_timestamp AS DATE);


DROP TABLE IF EXISTS ahemphill.homepage_funnel_sequenced;
CREATE TABLE ahemphill.homepage_funnel_sequenced AS

SELECT
	user_id,
	course_id,
	CASE
	WHEN date  BETWEEN '2016-09-20' AND '2016-09-27' THEN '09/20-09/27'
	WHEN date  BETWEEN '2016-09-30' AND '2016-10-03' THEN '09/30-10/03'
	WHEN date  BETWEEN '2016-10-05' AND '2016-10-10' THEN '10/05-10/10'
	WHEN date  BETWEEN '2016-10-12' AND '2016-10-17' THEN '10/12-10/17'
	WHEN date  BETWEEN '2016-10-20' AND '2016-10-24' THEN '10/20-10/24'
	WHEN date  BETWEEN '2016-10-25' AND '2016-11-01' THEN '10/25-11/01'
	END AS week,
	CASE
	WHEN
		course_page > 0 AND program_page = 0
	THEN
		'homepage --> course about page --> enroll'
	WHEN
		program_page > 0 AND course_page = 0
	THEN
		'homepage --> program page --> enroll'
	WHEN
		program_page > 0 AND course_page > 0 AND course_page > program_page
	THEN
		'homepage --> program page --> course page --> enroll'
	WHEN
		program_page > 0 AND course_page > 0 AND course_page < program_page
	THEN
		'homepage --> program page --> enroll'
	ELSE NULL
	END AS sequence	
FROM
(
	SELECT
		user_id,
		course_id,
		first_page,
		second_page,
		third_page,
		fourth_page,
		fifth_page,
		date,
		CASE 
		WHEN first_page like '%/course/%' THEN 1
		WHEN second_page like '%/course/%' THEN 2
		WHEN third_page like '%/course/%' THEN 3
		WHEN fourth_page like '%/course/%' THEN 4
		WHEN fifth_page like '%/course/%' THEN 5
		ELSE 0
		END AS course_page,
		CASE 
		WHEN first_page like '%/micromasters/%' THEN 1
		WHEN second_page like '%/micromasters/%' THEN 2
		WHEN third_page like '%/micromasters/%' THEN 3
		WHEN fourth_page like '%/micromasters/%' THEN 4
		WHEN fifth_page like '%/micromasters/%' THEN 5
		ELSE 0
		END AS program_page
	FROM
		(
		SELECT
			user_id,
			course_id,
			program_type,
			date,
			MAX(CASE WHEN page_order = 5 THEN path ELSE NULL END) AS first_page,
			MAX(CASE WHEN page_order = 4 THEN path ELSE NULL END) AS second_page,
			MAX(CASE WHEN page_order = 3 THEN path ELSE NULL END) AS third_page,
			MAX(CASE WHEN page_order = 2 THEN path ELSE NULL END) AS fourth_page,
			MAX(CASE WHEN page_order = 1 THEN path ELSE NULL END) AS fifth_page
		FROM 
			ahemphill.homepage_funnel
		WHERE 
			page_order <= 5
		GROUP BY 1,2,3,4
		) a
	WHERE
		(
		first_page = '/'
		OR second_page = '/'
		OR third_page = '/'
		OR fourth_page = '/'
		OR fifth_page = '/'
		)
) b
;


#DROP TABLE IF EXISTS ahemphill.homepage_funnel_concat;
#CREATE TABLE ahemphill.homepage_funnel_concat AS#

#SELECT 
#	user_id,
#	course_id,
#	program_type,
#	CONCAT(CONCAT(CONCAT(CONCAT(CONCAT(CONCAT(CONCAT(CONCAT(first_page, '--->'),second_page),'--->'),third_page),'--->'),fourth_page),'--->'),fifth_page) AS nav_path_length_5,
#	CONCAT(CONCAT(CONCAT(CONCAT(third_page,'--->'),fourth_page),'--->'),fifth_page) AS nav_path_length_3,
#	CONCAT(CONCAT(fourth_page,'--->'),fifth_page) AS nav_path_length_2,
#	fifth_page AS nav_path_length_1
#FROM
#(
#	SELECT
#		user_id,
#		course_id,
#		program_type,
#		MAX(CASE WHEN page_order = 5 THEN path ELSE NULL END) AS first_page,
#		MAX(CASE WHEN page_order = 4 THEN path ELSE NULL END) AS second_page,
#		MAX(CASE WHEN page_order = 3 THEN path ELSE NULL END) AS third_page,
#		MAX(CASE WHEN page_order = 2 THEN path ELSE NULL END) AS fourth_page,
#		MAX(CASE WHEN page_order = 1 THEN path ELSE NULL END) AS fifth_page
#	FROM 
#		ahemphill.homepage_funnel
#	WHERE 
#		page_order <= 5
#	GROUP BY 1,2,3
#) a

SELECT
        course_id,
        sequence,
        COUNT(1)
FROM
(
SELECT
	user_id,
	course_id,
	CASE
	WHEN
		course_page > 0 AND program_page = 0
	THEN
		'homepage --> course about page --> enroll'
	WHEN
		program_page > 0 AND course_page = 0
	THEN
		'homepage --> program page --> enroll'
	WHEN
		program_page > 0 AND course_page > 0 AND course_page > program_page
	THEN
		'homepage --> program page --> course page --> enroll'
	WHEN
		program_page > 0 AND course_page > 0 AND course_page < program_page
	THEN
		'homepage --> program page --> enroll'
	ELSE NULL
	END AS sequence	


FROM
(
SELECT
	user_id,
	course_id,
	first_page,
	second_page,
	third_page,
	fourth_page,
	fifth_page,
	CASE 
	WHEN first_page like '%/course/%' THEN 1
	WHEN second_page like '%/course/%' THEN 2
	WHEN third_page like '%/course/%' THEN 3
	WHEN fourth_page like '%/course/%' THEN 4
	WHEN fifth_page like '%/course/%' THEN 5
	ELSE 0
	END AS course_page,
	CASE 
	WHEN first_page like '%/micromasters/%' THEN 1
	WHEN second_page like '%/micromasters/%' THEN 2
	WHEN third_page like '%/micromasters/%' THEN 3
	WHEN fourth_page like '%/micromasters/%' THEN 4
	WHEN fifth_page like '%/micromasters/%' THEN 5
	ELSE 0
	END AS program_page
FROM
	(
	SELECT
		user_id,
		course_id,
		MAX(CASE WHEN page_order = 5 THEN path ELSE NULL END) AS first_page,
		MAX(CASE WHEN page_order = 4 THEN path ELSE NULL END) AS second_page,
		MAX(CASE WHEN page_order = 3 THEN path ELSE NULL END) AS third_page,
		MAX(CASE WHEN page_order = 2 THEN path ELSE NULL END) AS fourth_page,
		MAX(CASE WHEN page_order = 1 THEN path ELSE NULL END) AS fifth_page
	FROM 
		ahemphill.homepage_funnel
	WHERE 
		page_order <= 5
	GROUP BY 1,2,3
	) a
WHERE
	(
	first_page = '/'
	OR second_page = '/'
	OR third_page = '/'
	OR fourth_page = '/'
	OR fifth_page = '/'
	)
) b
) c
where sequence is not null
group by 1,2

