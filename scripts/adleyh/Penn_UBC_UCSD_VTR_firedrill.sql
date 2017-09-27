SELECT
	 a.course_id,
	 a.sum_enrolls_vtr,
	 a.sum_verifications,
	 a.vtr*100 AS vtr,
	 a.sum_bookings,
	 b.course_subject,
	 b.course_name,
	 b.course_announcement_date,
	 b.course_start_date,
	 b.course_verification_end_date,
	 b.course_end_date,
	 b.course_seat_price,
	 b.pacing_type
FROM
	course_stats_summary a
JOIN
	course_master b
ON
	a.course_id = b.course_id
AND 
	a.course_id IN
(
'course-v1:PennX+ROBO1x+1T2017',
'course-v1:UCSanDiegoX+CSE165x+2T2017',
'course-v1:UCSanDiegoX+DSE200x+2T2017',
'course-v1:UBCx+HtC1x+2T2017'
)

--avg vtr for a course in the last year

SELECT
	avg(vtr*100)
FROM
	course_stats_summary a
JOIN
	course_master b
ON
	a.course_id = b.course_id
WHERE 
	course_verification_end_date between '2016-06-01' AND '2017-06-01'
AND 
	sum_enrolls_vtr > 1000
AND 
	course_partner != 'Microsoft'
AND 
	is_wl = 0


SELECT
	CASE
		WHEN sum_enrolls_vtr BETWEEN 1000 AND 5000 THEN '1000-5000'
		WHEN sum_enrolls_vtr BETWEEN 5000 AND 10000 THEN '5000-10000'
		WHEN sum_enrolls_vtr BETWEEN 10000 AND 20000 THEN '10000-20000'
		WHEN sum_enrolls_vtr BETWEEN 20000 AND 100000000 THEN '>20000'
	END AS course_enrollment_group,
	avg(vtr*100)
FROM
	course_stats_summary a
JOIN
	course_master b
ON
	a.course_id = b.course_id
WHERE 
	course_verification_end_date between '2016-06-01' AND '2017-06-01'
AND 
	sum_enrolls_vtr > 1000
AND 
	course_partner != 'Microsoft'
AND 
	is_wl = 0
AND 
	course_name NOT LIKE '%Supply%'
GROUP BY 
	1

-- passing learners

SELECT
	a.user_id,
	c.user_email,
	a.course_id,
	a.current_enrollment_mode,
	b.percent_grade,
	b.letter_grade,
	b.passed_timestamp
FROM 
	production.d_user_course a
JOIN 
	lms_read_replica.grades_persistentcoursegrade b
ON 
	a.user_id = b.user_id
AND 
	a.course_id = b.course_id
AND 
	a.course_id IN
	(
	'course-v1:PennX+ROBO1x+1T2017',
	'course-v1:UCSanDiegoX+CSE165x+2T2017',
	'course-v1:UCSanDiegoX+DSE200x+2T2017',
	'course-v1:UBCx+HtC1x+2T2017'
	)
JOIN 
	production.d_user c
ON 
	a.user_id = c.user_id
AND 
	letter_grade != '';


-- pct progress through course
SELECT
	a.user_id,
	c.user_email,
	a.course_id,
	d.current_enrollment_mode,
	a.cnt_sections_attempted,
	b.cnt_sections_total,
	a.cnt_sections_attempted*100.0/b.cnt_sections_total AS pct_sections_attempted
FROM
(
	SELECT 
		user_id, 
		course_id, 
		count(distinct usage_key) as cnt_sections_attempted
	FROM 
		lms_read_replica.grades_persistentsubsectiongrade
	WHERE 
		course_id IN
		(
		'course-v1:PennX+ROBO1x+1T2017',
		'course-v1:UCSanDiegoX+CSE165x+2T2017',
		'course-v1:UCSanDiegoX+DSE200x+2T2017',
		'course-v1:UBCx+HtC1x+2T2017'
		)
	GROUP BY
		user_id,
		course_id
) a
JOIN
(
SELECT 
	course_id, 
	count(distinct usage_key) as cnt_sections_total
FROM 
	lms_read_replica.grades_persistentsubsectiongrade
GROUP BY
	course_id
) b
ON 
	a.course_id = b.course_id
JOIN
	production.d_user c
ON
	a.user_id = c.user_id
JOIN
        production.d_user_course d
ON
        a.user_id = d.user_id
AND
        a.course_id = d.course_id;

--engaged learners

select a.course_id,
weekly_engagement_level,
count(1)
from user_activity_engagement_weekly a
JOIN 
	course_master b
ON 
	a.course_id = b.course_id
AND 
	b.course_subject = 'Computer Science'
AND 
	b.course_start_date >= '2016-07-01'

AND 
	course_partner != 'Microsoft'
and a.course_id IN
(
'course-v1:PennX+ROBO1x+1T2017',
'course-v1:UCSanDiegoX+CSE165x+2T2017',
'course-v1:UCSanDiegoX+DSE200x+2T2017',
'course-v1:UBCx+HtC1x+2T2017'
)
and week = 'week_1'
group by 1,2

--retained learners

select a.course_id,
weekly_engagement_level,
sum(cnt_users)
from user_activity_engagement_weekly_agg a
JOIN 
	course_master b
ON 
	a.course_id = b.course_id
AND 
	b.course_subject = 'Computer Science'
AND 
	b.course_start_date >= '2016-07-01'

AND 
	course_partner != 'Microsoft'
and a.course_id IN
(
'course-v1:PennX+ROBO1x+1T2017',
'course-v1:UCSanDiegoX+CSE165x+2T2017',
'course-v1:UCSanDiegoX+DSE200x+2T2017',
'course-v1:UBCx+HtC1x+2T2017'
)
and week = 'week_2'
and week_1_engagement_level != 'no_engagement'
group by 1,2

-- pre or post course start enrollment
SELECT
	CASE 
		WHEN a.first_enrollment_time >= b.course_start_date THEN 'after' 
		ELSE 'before' 
	END AS enroll_before_or_after_course_start,
	a.course_id,
	count(1) AS cnt_enrolls,
	SUM(CASE WHEN current_enrollment_mode = 'verified' THEN 1 ELSE 0 END)*100.0/COUNT(1) AS vtr
FROM
	production.d_user_course a
JOIN 
	course_master b
ON 
	a.course_id = b.course_id
AND 
	a.course_id IN
	(
	'course-v1:PennX+ROBO1x+1T2017',
	'course-v1:UCSanDiegoX+CSE165x+2T2017',
	'course-v1:UCSanDiegoX+DSE200x+2T2017',
	'course-v1:UBCx+HtC1x+2T2017'
	)
GROUP BY
	1,2;

--engagement

SELECT
	CASE 
		WHEN a.first_enrollment_time >= b.course_start_date THEN 'after' 
		ELSE 'before' 
	END AS enroll_before_or_after_course_start,
		a.course_id,
	b.pacing_type,
	b.course_partner,
	b.course_subject,
	COUNT(1)*100.0/d.cnt_total_enrolls AS pct_of_total_enrolls,
	count(1) AS cnt_enrolls,
	SUM(CASE WHEN current_enrollment_mode = 'verified' THEN 1 ELSE 0 END)*100.0/COUNT(1) AS vtr,
	COUNT(c.user_id)*100.0/COUNT(1) AS pct_engaged,
FROM
	production.d_user_course a
JOIN 
	course_master b
ON 
	a.course_id = b.course_id
AND 
	a.course_id IN
	(
	'course-v1:PennX+ROBO1x+1T2017',
	'course-v1:UCSanDiegoX+CSE165x+2T2017',
	'course-v1:UCSanDiegoX+DSE200x+2T2017',
	'course-v1:UBCx+HtC1x+2T2017'
	)
LEFT JOIN
(
	SELECT
		 user_id,
		 course_id
	FROM 
	 	production.f_user_activity
	WHERE 
	 	activity_type != 'ACTIVE'
	 	AND 
	 		course_id IN
	 	(
		'course-v1:PennX+ROBO1x+1T2017',
		'course-v1:UCSanDiegoX+CSE165x+2T2017',
		'course-v1:UCSanDiegoX+DSE200x+2T2017',
		'course-v1:UBCx+HtC1x+2T2017'
		)
	GROUP BY 
		1,2
) c
ON 
	a.user_id = c.user_id
AND 
	a.course_id = c.course_id
JOIN
(
	SELECT
		course_id,
		COUNT(1) AS cnt_total_enrolls
	FROM
		production.d_user_course
	GROUP BY 1


) d
ON
	a.course_id = d.course_id  
GROUP BY
	1,2,3,4,d.cnt_total_enrolls;

-- country level breakdown

SELECT
	d.country_name, 
	a.course_id,
	count(1) AS cnt_enrolls,
	SUM(CASE WHEN current_enrollment_mode = 'verified' THEN 1 ELSE 0 END)*100.0/COUNT(1) AS vtr
FROM
	production.d_user_course a
JOIN 
	course_master b
ON 
	a.course_id = b.course_id
AND 
	a.course_id IN
	(
	'course-v1:PennX+ROBO1x+1T2017',
	'course-v1:UCSanDiegoX+CSE165x+2T2017',
	'course-v1:UCSanDiegoX+DSE200x+2T2017',
	'course-v1:UBCx+HtC1x+2T2017'
	)
JOIN 
	production.d_user c
ON 
	a.user_id = c.user_id
JOIN 
	production.d_country d
ON 
	c.user_last_location_country_code = d.user_last_location_country_code
GROUP BY 
	1,2
HAVING 
	count(1) > 100
ORDER BY 
	course_id desc, vtr desc;


--price comparison

SELECT 
	CASE
		when course_seat_price< 50 then '<50'
		when course_seat_price<100 then '>50 and <100'
		when course_seat_price>=100 then '>100'
	end AS seat_price,
	avg(vtr*100) AS vtr,
	count(1) as cnt_courses
FROM
	course_stats_summary a
JOIN 
	course_master b
ON 
	a.course_id = b.course_id
AND 
	b.course_subject = 'Computer Science'
AND 
	b.course_start_date >= '2017-01-01'
AND 
	sum_enrolls_vtr > 1000
AND 
	course_partner != 'Microsoft'
GROUP BY 
	1

---

DROP TABLE IF EXISTS ahemphill.pacing_vtr_engagement_enrollment_date;
CREATE TABLE IF NOT EXISTS ahemphill.pacing_vtr_engagement_enrollment_date AS
SELECT
	CASE 
		WHEN a.first_enrollment_time >= b.course_start_date THEN 'after' 
		ELSE 'before' 
	END AS enroll_before_or_after_course_start,
		a.course_id,
	b.pacing_type,
	b.course_partner,
	b.course_subject,
	SUM(CASE WHEN c.weekly_engagement_level LIKE '%high%' THEN 1 ELSE 0 END)*100.0/COUNT(1) AS pct_highly_engaged,
	SUM(CASE WHEN c.weekly_engagement_level != 'no_engagement' THEN 1 ELSE 0 END)*100.0/COUNT(1) AS pct_ever_engaged,
	count(1) AS cnt_enrolls,
	SUM(CASE WHEN current_enrollment_mode = 'verified' THEN 1 ELSE 0 END)*100.0/COUNT(1) AS vtr
FROM
	production.d_user_course a
JOIN 
	course_master b
ON 
	a.course_id = b.course_id
	AND b.course_start_date between '2016-06-01' and '2017-06-01'
LEFT JOIN
(
	SELECT
		 user_id,
		 course_id,
		 weekly_engagement_level
	FROM 
	 	business_intelligence.user_activity_engagement_weekly
	WHERE 
	 	week = 'week_1'
) c
ON 
	a.user_id = c.user_id
AND 
	a.course_id = c.course_id

GROUP BY
	1,2,3,4,5;

