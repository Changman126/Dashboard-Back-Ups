DROP TABLE IF EXISTS ahemphill.optimizely_exposure_duplicate;
CREATE TABLE IF NOT EXISTS ahemphill.optimizely_exposure_duplicate AS

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

DROP TABLE IF EXISTS ahemphill.optimizely_exposure;
CREATE TABLE IF NOT EXISTS ahemphill.optimizely_exposure AS

SELECT
	first_exposure_timestamp,
	a.user_id,
	a.experiment_name,
	variation_name,
	experiment_path
FROM
	ahemphill.optimizely_exposure_duplicate a
JOIN
	(
		SELECT
			user_id,
			experiment_name,
			COUNT(DISTINCT variation_name) AS cnt_variations
		FROM
			ahemphill.optimizely_exposure_duplicate
		GROUP BY
			user_id,
			experiment_name
		HAVING
			COUNT(DISTINCT variation_name) = 1
	) b
ON
	a.user_id = b.user_id
AND
	a.experiment_name = b.experiment_name
;

DROP TABLE IF EXISTS ahemphill.experiment_results;
CREATE TABLE IF NOT EXISTS ahemphill.experiment_results AS

SELECT
	a.user_id,
	first_exposure_timestamp,
	experiment_name,
	variation_name,
	experiment_path,
	SUM(is_active) AS cnt_days_active,
	SUM(active_activity_count) AS sum_active_activity,
	SUM(is_engaged) AS cnt_days_engaged,
	SUM(engaged_activity_count) AS sum_engaged_activity,
	SUM(is_engaged_video) AS cnt_days_engaged_video,
	SUM(video_activity_count) AS sum_avideo_activity,
	SUM(is_engaged_problem) AS cnt_days_engaged_problem,
	SUM(problem_activity_count) AS sum_problem_activity,
	SUM(is_engaged_forum) AS cnt_days_engaged_forum,
	SUM(forum_activity_count) AS sum_forum_activity
FROM
	ahemphill.experiment_exposure a
LEFT JOIN
	tmp_stats_summary_user b
ON
	a.user_id b.user_id
AND
	b.absolute_date >= DATE(a.first_exposure_timestamp)