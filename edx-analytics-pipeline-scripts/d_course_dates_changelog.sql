--Create Changelog Table to record a snapshot of course dates on any given date
CREATE TABLE IF NOT EXISTS business_intelligence.course_dates_changelog (
	snapshot_date DATE,
	course_id VARCHAR(555),
	announcement_time DATE,
	start_time DATE,
	end_time DATE,
	enrollment_start_time DATE,
	enrollment_end_time DATE,
	pacing_type VARCHAR(555)
);

--Insert Daily Pull of d_course
INSERT INTO business_intelligence.course_dates_changelog
SELECT
	CURRENT_DATE(),
	course_id,
	announcement_time,
	start_time,
	end_time,
	enrollment_start_time,
	enrollment_end_time,
	pacing_type
FROM
	production.d_course;

--Create table to house date changes over time
CREATE TABLE IF NOT EXISTS business_intelligence.course_date_changes (
	change_date DATE,
	course_id VARCHAR(555),
	new_start_time DATE,
	original_start_time DATE,
	new_end_time DATE,
	original_end_time DATE,
	new_pacing_type VARCHAR(555),
	original_pacing_type VARCHAR(555),
	type_change VARCHAR(555)
);	
	
--Look at current day vs previous day changelog and insert course_ids with changes to dates or pacing type	
INSERT INTO business_intelligence.course_date_changes
SELECT
	CURRENT_DATE() AS change_date,
	current_day.course_id,
	current_day.start_time AS new_start_time,
	previous_day.start_time AS original_start_time,
	current_day.end_time AS new_end_time,
	previous_day.end_time AS original_end_time,
	current_day.pacing_type AS new_pacing_type,
	previous_day.pacing_type AS original_pacing_type,
	CASE
		WHEN current_day.start_time != previous_day.start_time THEN 'Start Date'
		WHEN current_day.end_time != previous_day.end_time THEN 'End Date'
		WHEN current_day.pacing_type != previous_day.pacing_type THEN 'Pacing Type'
	END AS type_change
FROM
	(
		SELECT
			course_id,
			announcement_time,
			start_time,
			end_time,
			pacing_type
		FROM
			business_intelligence.course_dates_changelog
		WHERE
			snapshot_date = CURRENT_DATE()
	) current_day
INNER JOIN
	(
		SELECT
			course_id,
			announcement_time,
			start_time,
			end_time,
			pacing_type
		FROM
			business_intelligence.course_dates_changelog
		WHERE
			snapshot_date = CURRENT_DATE() - 1
	) previous_day
ON
	current_day.course_id = previous_day.course_id
WHERE
	current_day.start_time != previous_day.start_time
OR
	current_day.end_time != previous_day.end_time
OR
	current_day.pacing_type != previous_day.pacing_type;