/*
--do this once to initialize

DROP TABLE IF EXISTS ahemphill.experiment_exposure_summary;
CREATE TABLE IF NOT EXISTS ahemphill.experiment_exposure_summary AS

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
		PARTITION BY COALESCE(
			CAST(identify.user_id AS VARCHAR),
			CAST(d_user.user_id AS VARCHAR), 
			CAST(event.user_id AS VARCHAR)
		), experiment_name, variation_name 
		ORDER BY event.timestamp ASC) AS experiment_path
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
			AND date >= '2016-09-01'
	) event
	LEFT JOIN
		business_intelligence.identify identify
	ON 
		event.anonymous_id = identify.anonymous_id
	LEFT JOIN
		production.d_user d_user
	ON 
		event.user_id = d_user.user_username
) sub
WHERE
	REGEXP_COUNT(user_id, '[a-zA-Z]') = 0
	AND user_id IS NOT NULL
GROUP BY 
	user_id,
	experiment_name,
	variation_name,
	experiment_path;

*/

--pull daily experiment views from the event log
--attempt to find the correct user_id based on a few sources
--drop entries where we can't find anything

DROP TABLE IF EXISTS experiment_exposure_daily;
CREATE TABLE IF NOT EXISTS experiment_exposure_daily AS

SELECT
	CAST(MIN(event.timestamp) AS DATETIME) AS first_exposure_timestamp,
	COALESCE(
		CAST(identify.user_id AS VARCHAR),
		CAST(d_user.user_id AS VARCHAR), 
		CAST(event.user_id AS VARCHAR)
	) AS user_id,
	event.experiment_name,
	event.variation_name,
	COUNT(1) AS cnt_experiment_views
FROM 
(
	SELECT
		timestamp,
		user_id,
		anonymous_id,
		experimentname AS experiment_name,
		variationname AS variation_name
	FROM 
		experimental_events_run14.event_records
	WHERE 
		event_type = 'Experiment Viewed'
		AND date = CAST(CURRENT_DATE()-1 AS VARCHAR)
) event
LEFT JOIN
	business_intelligence.identify identify
ON 
	event.anonymous_id = identify.anonymous_id
LEFT JOIN
	production.d_user d_user
ON 
	event.user_id = d_user.user_username
WHERE
	REGEXP_COUNT(
			COALESCE(
			CAST(identify.user_id AS VARCHAR),
			CAST(d_user.user_id AS VARCHAR), 
			CAST(event.user_id AS VARCHAR)
		), '[a-zA-Z]') = 0
	AND COALESCE(
			CAST(identify.user_id AS VARCHAR),
			CAST(d_user.user_id AS VARCHAR), 
			CAST(event.user_id AS VARCHAR)
	) IS NOT NULL
GROUP BY 
	2,
	event.experiment_name,
	event.variation_name;

--combine with previous experiment exposure, de-dupe, and store in tmp table

DROP TABLE IF EXISTS experiment_exposure_stg;
CREATE LOCAL TEMPORARY TABLE experiment_exposure_stg ON COMMIT PRESERVE ROWS AS
	SELECT
		MIN(unioned.first_exposure_timestamp) AS first_exposure_timestamp,
		CAST(unioned.user_id AS INTEGER),
		unioned.experiment_name,
		unioned.variation_name,
		SUM(unioned.cnt_experiment_views) AS cnt_experiment_views
	FROM 
	(
		SELECT
			first_exposure_timestamp,
			user_id,
			experiment_name,
			variation_name,
			cnt_experiment_views
		FROM 
			experiment_exposure_daily

		UNION ALL

		SELECT
			first_exposure_timestamp,
			user_id,
			experiment_name,
			variation_name,
			cnt_experiment_views
		FROM 
			experiment_exposure_summary
	) unioned
	GROUP BY
		unioned.user_id,
		unioned.experiment_name,
		unioned.variation_name;

--drop previous summary table and load with results from tmp table

DROP TABLE IF EXISTS experiment_exposure_summary;
CREATE TABLE IF NOT EXISTS experiment_exposure_summary (
	first_exposure_timestamp DATETIME,
	user_id INTEGER,
	experiment_name VARCHAR(255),
	variation_name VARCHAR(255),
	cnt_experiment_views INTEGER
);

INSERT INTO experiment_exposure_summary SELECT * FROM experiment_exposure_stg;
