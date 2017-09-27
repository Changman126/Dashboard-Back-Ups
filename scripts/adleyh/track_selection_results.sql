/*
Intent of this pipeline is to pull user_id, variation, and time of first exposure across Optimizely and email tests through Sailthru.
Once aggregating the exposure information, we join to a table which tracks key metrics daily.
Until Sailthru is logged in the DW via some deterministic means, we will rely on manually writing information to a table in the
curated schema.
*/

/*
Pull daily experiment exposures from event table
Have to do some hackiness to align anonymous ids and user_ids.
If I can't find a valid user_id on the dya of exposure, I throw it out.
*/


DROP TABLE IF EXISTS tmp_optimizely_exposure_daily;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_optimizely_exposure_daily ON COMMIT PRESERVE ROWS AS

SELECT
	MIN(first_exposure_timestamp) AS first_exposure_timestamp,
	user_id,
	experiment_name,
	variation_name,
	experiment_path
FROM
(
	SELECT
		CAST(event.timestamp AS DATETIME) AS first_exposure_timestamp,
		COALESCE(
			CAST(identify.user_id AS VARCHAR),
			CAST(d_user.user_id AS VARCHAR), 
			CAST(event.user_id AS VARCHAR)
		) AS user_id,
		event.experiment_name,
		event.variation_name,
		FIRST_VALUE(experiment_path) OVER(
		PARTITION BY 
			COALESCE(
				CAST(identify.user_id AS VARCHAR),
				CAST(d_user.user_id AS VARCHAR), 
				CAST(event.user_id AS VARCHAR)
					), 
			experiment_name, 
			variation_name 
		ORDER BY timestamp ASC) AS experiment_path
	FROM 
	(
		SELECT
			timestamp,
			user_id,
			anonymous_id,
			experimentname AS experiment_name,
			variationname AS variation_name,
			path AS experiment_path
		FROM 
			experimental_events_run14.event_records
		WHERE 
			event_type = 'Experiment Viewed'
	) event
	LEFT JOIN
		business_intelligence.identify identify
	ON 
		event.anonymous_id = identify.anonymous_id
	LEFT JOIN
		production.d_user d_user
	ON 
		event.user_id = d_user.user_username
) a
WHERE
	REGEXP_COUNT(user_id, '[a-zA-Z]') = 0
	AND user_id IS NOT NULL
GROUP BY 
	user_id,
	experiment_name,
	variation_name,
	experiment_path;

--take previous exposures, union to today's exposures, and figure out if any of them are new.

DROP TABLE IF EXISTS tmp_optimizely_exposure_historical;
CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_optimizely_exposure_historical ON COMMIT PRESERVE ROWS AS

	SELECT
		MIN(first_exposure_timestamp) AS first_exposure_timestamp,
		user_id,
		experiment_name,
		variation_name,
		a.experiment_path
	FROM
	(
		SELECT
			first_exposure_timestamp,
			user_id,
			experiment_name,
			variation_name,
			experiment_path
		FROM
			tmp_optimizely_exposure_daily
	) a
	GROUP BY 
		user_id,
		experiment_name,
		variation_name,
		experiment_path;

--dedupe the table based on whether a user has a single variation associated with them

DROP TABLE IF EXISTS ahemphill.optimizely_exposure_historical;
CREATE TABLE IF NOT EXISTS ahemphill.optimizely_exposure_historical AS

SELECT
	first_exposure_timestamp,
	a.user_id,
	a.experiment_name,
	a.variation_name,
	a.experiment_path
FROM
	tmp_optimizely_exposure_historical a
JOIN
	(
		SELECT
			user_id,
			experiment_name,
			experiment_path,
			COUNT(DISTINCT variation_name) AS cnt_variations
		FROM
			tmp_optimizely_exposure_historical
		GROUP BY
			user_id,
			experiment_name,
			experiment_path
		HAVING
			COUNT(DISTINCT variation_name) = 1
	) b
ON
	a.user_id = b.user_id
AND
	a.experiment_name = b.experiment_name;

DROP TABLE IF EXISTS ahemphill.track_selection_results_stg;
CREATE TABLE IF NOT EXISTS ahemphill.track_selection_results_stg AS

SELECT 
	a.*, 
COALESCE(b.course_id, REPLACE(
	REPLACE(
		REPLACE(
			REGEXP_SUBSTR(a.experiment_path, '(course-v1.*?)/', 1, 1),'/',''),'%3',':'),'%2','+')) AS course_id
FROM  
	ahemphill.optimizely_exposure_historical a
LEFT JOIN 
	production.d_course b 
ON 
	a.experiment_path = REGEXP_SUBSTR(b.marketing_url, '\/course.*', 1, 1)
WHERE
	experiment_name = 'Skip Track Selection'
;

DROP TABLE IF EXISTS ahemphill.track_selection_results_stg2;
CREATE TABLE IF NOT EXISTS ahemphill.track_selection_results_stg2 AS

SELECT
	first_exposure_timestamp,
	a.user_id,
	experiment_name,
	variation_name,
	a.course_id,
	SUM(CASE WHEN activity_type = 'ACTIVE' THEN 1 ELSE 0 END) AS cnt_days_active,
	SUM(CASE WHEN activity_type IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM', 
		'POSTED_FORUM') THEN 1 ELSE 0 END) AS cnt_days_engaged,
	SUM(CASE WHEN activity_type = 'ACTIVE' THEN number_of_activities ELSE 0 END) AS sum_active_activity,
	SUM(CASE WHEN activity_type IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM', 
		'POSTED_FORUM') THEN number_of_activities ELSE 0 END) AS sum_engaged_activity
FROM 
	ahemphill.track_selection_results_stg a
LEFT JOIN 
	production.f_user_activity b
ON 
	a.user_id = b.user_id
AND 
	a.course_id = b.course_id
AND 
	b.date >= date(a.first_exposure_timestamp)
GROUP BY 
	first_exposure_timestamp,
	a.user_id,
	experiment_name,
	variation_name,
	a.course_id;

DROP TABLE IF EXISTS ahemphill.track_selection_results;
CREATE TABLE IF NOT EXISTS ahemphill.track_selection_results AS
SELECT
	first_exposure_timestamp,
	a.user_id,
	experiment_name,
	variation_name, 
	a.course_id,
	c.current_enrollment_mode,
	CASE WHEN cnt_days_active > 0 THEN 1 ELSE 0 END AS is_active,
	CASE WHEN cnt_days_engaged > 0 THEN 1 ELSE 0 END AS is_engaged,
	cnt_days_active,
	cnt_days_engaged,
	sum_active_activity,
	sum_engaged_activity
FROM
	ahemphill.track_selection_results_stg2 a
JOIN
	production.d_user_course c
ON 
	a.user_id = c.user_id
AND 
	a.course_id = c.course_id
AND 
	DATE(c.first_enrollment_time) >= DATE(a.first_exposure_timestamp);

select
user_id,
referrer,
case when referrer like '%choose%' then 'track_selection'
when referrer like '%dashboard%' then 'dashboard'
when referrer like '%/courses/course-v1%upgrade=true%' then 'course_page_w_upgrade'
when referrer like '%/courses/course-v1%' then 'course_page_wout_upgrade'
end as referral_source
from 
experimental_events_run14.event_records 
where CAST(user_id AS VARCHAR) IN
(
'13964042',
'13963020',
'13961513',
'13960417',
'13959794',
'13959277',
'13959264',
'13955030',
'13952668',
'13952258',
'13944647',
'13944391',
'13943665',
'13943562',
'13942662',
'13933223',
'13931375',
'13930335',
'13929770',
'13925222',
'13922206',
'13920528',
'13919007',
'13918067',
'13916661',
'13915949',
'13912727',
'13905756',
'13902779',
'13902124',
'13900144',
'13899214',
'13893551',
'13892692',
'13892056',
'13889436',
'13889337',
'13888931',
'13885604',
'13880990',
'13879242',
'13870849',
'13870818',
'13867578',
'13863248',
'13860343',
'13858048',
'13857881',
'13857259',
'13855662',
'13855261',
'13851803',
'13850436',
'13849451',
'13822781',
'13764700',
'11140415',
'10866918',
'10262065',
'8997029',
'7999792',
'7667368',
'7637067',
'7364602',
'6066639',
'5482394',
'3343653',
'2765962',
'2112919',
'2076476',
'2074552'


) and 
event_type = 'edx.bi.ecommerce.basket.payment_selected'
