DROP TABLE IF EXISTS ahemphill.ifl_fb_identical_courses;
CREATE TABLE IF NOT EXISTS ahemphill.ifl_fb_identical_courses AS

SELECT
	conversion_type, 
	course_id,
	COUNT(distinct channel) AS num_channels,
	SUM(cnt) as total_count
FROM
(
	SELECT
		conversion_type,
		course_id,
		CASE WHEN 
		(campaign_source like '%ifl%' OR referring_domain like '%ifl%') THEN 'ifl'
		ELSE 'fb' END as channel,
		campaign_name,
		count(1) AS cnt
	FROM 
		ahemphill.campaign_conversions 
	WHERE 
		(campaign_source like '%ifl%' OR referring_domain like '%ifl%')
		OR (campaign_source = 'facebook' AND campaign_medium like '%paid%')
	GROUP BY 
		1,2,3,4
) a
GROUP BY 1,2
HAVING COUNT(distinct channel) > 1;

DROP TABLE IF EXISTS ahemphill.ifl_fb_engagement_campaigns;
CREATE TABLE IF NOT EXISTS ahemphill.ifl_fb_engagement_campaigns AS
SELECT
	a.* 
FROM 
	ahemphill.campaign_conversions a
JOIN ahemphill.ifl_fb_identical_courses b
ON a.course_id = b.course_id
AND a.conversion_type = b.conversion_type
WHERE
(
	(campaign_source like '%ifl%' OR referring_domain like '%ifl%')
	OR (campaign_source = 'facebook' AND campaign_medium like '%paid%')
);

DROP TABLE IF EXISTS ahemphill.ifl_fb_engagement_compare_activity;
CREATE TABLE IF NOT EXISTS ahemphill.ifl_fb_engagement_compare_activity AS
SELECT
	date,
	user_id,
	a.course_id,
	b.conversion_type,
	SUM(number_of_activities) AS cnt_activities
FROM
	f_user_activity a
JOIN ahemphill.ifl_fb_identical_courses b
ON a.course_id = b.course_id
AND b.conversion_type = 'enrollment'
GROUP BY
	1,2,3,4;

DROP TABLE IF EXISTS ahemphill.ifl_fb_engagement_compare;
CREATE TABLE IF NOT EXISTS ahemphill.ifl_fb_engagement_compare AS

SELECT 
	campaign_source,
	course_id,
	SUM(CASE WHEN datediff('day', date(conversion_time), earliest_activity_date) >= 1 THEN 1 else 0 END) AS cnt_active,
	COUNT(1) as cnt_enrolls
FROM
(
	SELECT
		a.user_id, 
		a.conversion_time, 
		a.course_id, 
		a.campaign_source, 
		a.campaign_medium, 
		a.campaign_name, 
		MIN(date) AS earliest_activity_date
	FROM
		ahemphill.ifl_fb_engagement_campaigns a
	LEFT JOIN
		ahemphill.ifl_fb_engagement_compare_activity b
	ON a.user_id = b.user_id
	AND a.course_id = b.course_id
	AND a.conversion_type = 'enrollment'
	GROUP BY 1,2,3,4,5,6
) a
GROUP BY 
	1,2;


---

SELECT 
campaign_source,
course_id,
SUM(CASE WHEN datediff('day',date(conversion_time),earliest_activity_date) >= 1 THEN 1 else 0 END) AS cnt_active,
COUNT(1) as cnt_enrolls
from
(
select a.user_id, a.conversion_time, a.course_id, a.campaign_source, a.campaign_medium, a.campaign_name, MIN(date) AS earliest_activity_date
from ahemphill.ifl_fb_engagement_compare a
LEFT JOIN
ahemphill.ifl_fb_engagement_compare_activity b
ON a.user_id = b.user_id
AND a.course_id = b.course_id
GROUP BY 1,2,3,4,5,6
) a
group by 1,2


select a.user_id, a.conversion_time, a.course_id, a.campaign_source, a.campaign_medium, a.campaign_name, MIN(date) AS earliest_activity_date,
datediff('day',conversion_time,min(date))
from ahemphill.ifl_fb_engagement_compare a
LEFT JOIN
ahemphill.ifl_fb_engagement_compare_activity b
ON a.user_id = b.user_id
AND a.course_id = b.course_id
GROUP BY 1,2,3,4,5,6

DROP TABLE IF EXISTS ahemphill.ifl_multiples_courses_enrolled;
CREATE TABLE IF NOT EXISTS ahemphill.ifl_multiples_courses_enrolled AS

SELECT 
	cnt,
	count(user_id)
FROM
(
	SELECT
		a.user_id,
		count(1) AS cnt,
		SUM(CASE WHEN datediff('day',conversion_time, first_enrollment_time) >= 14 THEN 1 ELSE 0 END)
	FROM
		d_user_course a
	JOIN
	(
		SELECT user_id, date(conversion_time) as conversion_time
		FROM ahemphill.campaign_conversions 
		WHERE extract('month' from date(conversion_time)) = 8
		AND conversion_type = 'enrollment'
		AND campaign_name is not null
		AND campaign_source like '%ifl%'
	) b
	ON a.user_id = b.user_id

	GROUP BY 1
) a
GROUP BY 1

