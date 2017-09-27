/*
Intent of this pipeline is to pull user_id, variation, and time of first exposure across Optimizely and email tests through Sailthru.
Once aggregating the exposure information, we join to a table which tracks key metrics daily.
Until Sailthru is logged in the DW via some deterministic means, we will rely on manually writing information to a table in the
curated schema.
*/

/*
Pull daily experiment exposures from event table
Have to do some hackiness to align anonymous ids and user_ids.
*/

-- DROP TABLE IF EXISTS tmp_optimizely_exposure_daily;
-- CREATE LOCAL TEMPORARY TABLE IF NOT EXISTS tmp_optimizely_exposure_daily ON COMMIT PRESERVE ROWS AS
DROP TABLE ahemphill.tmp_optimizely_exposure_daily;
CREATE TABLE ahemphill.tmp_optimizely_exposure_daily AS

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
			received_at AS timestamp,
			user_id,
			anonymous_id,
			experimentname AS experiment_name,
			variationname AS variation_name,
			path AS experiment_path
		FROM 
			experimental_events_run14.event_records event
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
AND 
	user_id IS NOT NULL
GROUP BY 
	user_id,
	experiment_name,
	variation_name,
	experiment_path;

--take previous exposures, union to today's exposures, and figure out if any of them are new.

CREATE TABLE ahemphill.tmp_optimizely_exposure_historical AS

	SELECT
		MIN(first_exposure_timestamp) AS first_exposure_timestamp,
		user_id,
		experiment_name,
		variation_name,
		experiment_path
	FROM
	(
		SELECT
			first_exposure_timestamp,
			user_id,
			experiment_name,
			variation_name,
			experiment_path
		FROM
			ahemphill.tmp_optimizely_exposure_daily
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
	variation_name,
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
			ahemphill.tmp_optimizely_exposure_historical
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



--combine deduped optimizely experiments with whatever is contained in the table in the curated schema

DROP TABLE IF EXISTS ahemphill.experiment_exposure;
CREATE TABLE IF NOT EXISTS ahemphill.experiment_exposure AS

SELECT
	MIN(first_exposure_timestamp) AS first_exposure_timestamp,
	a.user_id,
	a.experiment_name,
	variation_name,
	experiment_path
FROM
	(
		SELECT
			first_exposure_timestamp,
			user_id,
			experiment_name,
			variation_name,
			experiment_path
		FROM
			ahemphill.optimizely_exposure_historical

		/*
		--placeholder for future tables that we'll want to bring in

		UNION ALL

		SELECT
			first_exposure_timestamp,
			a.user_id,
			a.experiment_name,
			variation_name,
			experiment_path
		FROM
			curated.email_experiments
		*/
	) a
GROUP BY
	a.user_id,
	a.experiment_name,
	variation_name,
	experiment_path;

--join all experiment exposures with results table. aggregate based on exposure time.

DROP TABLE IF EXISTS ahemphill.experiment_results;
CREATE TABLE IF NOT EXISTS ahemphill.experiment_results AS

SELECT
	a.user_id,
	first_exposure_timestamp,
	experiment_name,
	variation_name,
	experiment_path,
	MAX(is_active) AS is_active,
	SUM(is_active) AS cnt_days_active,
	SUM(cnt_active_activity) AS sum_active_activity,
	MAX(is_engaged) AS is_engaged,
	SUM(is_engaged) AS cnt_days_engaged,
	SUM(cnt_engaged_activity) AS sum_engaged_activity,
	SUM(is_engaged_video) AS cnt_days_engaged_video,
	SUM(cnt_video_activity) AS sum_video_activity,
	SUM(is_engaged_problem) AS cnt_days_engaged_problem,
	SUM(cnt_problem_activity) AS sum_problem_activity,
	SUM(is_engaged_forum) AS cnt_days_engaged_forum,
	SUM(cnt_forum_activity) AS sum_forum_activity
FROM
	ahemphill.experiment_exposure a
LEFT JOIN
	(
		SELECT
			date AS absolute_date,
			user_id,
			MAX(is_active) AS is_active,
			SUM(cnt_active_activity) AS cnt_active_activity,
			MAX(is_engaged) AS is_engaged,
			SUM(cnt_engaged_activity) AS cnt_engaged_activity,
			MAX(is_engaged_video) AS is_engaged_video,
			SUM(cnt_video_activity) AS cnt_video_activity,
			MAX(is_engaged_problem) AS is_engaged_problem,
			SUM(cnt_problem_activity) AS cnt_problem_activity,
			MAX(is_engaged_forum) AS is_engaged_forum,
			SUM(cnt_forum_activity) AS cnt_forum_activity
		FROM
			business_intelligence.activity_engagement_user_daily
		GROUP BY
			date,
			user_id
	) b
ON
	a.user_id = b.user_id
AND
	b.absolute_date >= DATE(a.first_exposure_timestamp)
GROUP BY
	a.user_id,
	first_exposure_timestamp,
	experiment_name,
	variation_name,
	experiment_path;
