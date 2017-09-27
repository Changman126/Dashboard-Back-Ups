DROP TABLE IF EXISTS ahemphill.p_verify_model;
CREATE TABLE IF NOT EXISTS ahemphill.p_verify_model AS 

SELECT
	*
FROM
(
	SELECT 
		a.*,
		b.first_enrollment_time,
		b.first_verified_enrollment_time,
		CASE WHEN DATE(b.first_verified_enrollment_time) <= DATE(a.date) THEN 1 ELSE 0 END AS has_verified,
		rank() over (partition by a.user_id, a.course_id order by date asc) AS days_from_content_availability
	FROM 
		business_intelligence.user_activity_engagement_daily a 
	JOIN 
		production.d_user_course b
	ON
		a.user_id = b.user_id
	AND
		a.course_id = b.course_id
	AND
		a.week IN ('week_1', 'week_2')
) a
WHERE
	has_verified = 0 
	OR
	DATE(first_verified_enrollment_time) = DATE(date);

DROP TABLE IF EXISTS ahemphill.p_verify_model_prior_completions;
CREATE TABLE IF NOT EXISTS ahemphill.p_verify_model_prior_completions AS 

SELECT
	a.user_id,
	a.course_id,
	SUM(has_passed) AS cnt_prior_passes
FROM
(
	SELECT 
		user_id, 
		course_id,
		first_enrollment_time
	FROM 
		ahemphill.p_verify_model
	GROUP BY
		user_id, 
		course_id,
		first_enrollment_time
) a
LEFT JOIN
(
	SELECT
		d_user_course.user_id,
		d_user_course.course_id,
		first_enrollment_time,
		CASE WHEN passed_timestamp IS NOT NULL THEN 1 ELSE 0 END AS has_passed
	FROM
		production.d_user_course d_user_course
	LEFT JOIN
		business_intelligence.course_completion_user comp
	ON
		d_user_course.user_id = comp.user_id
	AND
		d_user_course.course_id = comp.course_id
) comp
ON
	a.user_id = comp.user_id
AND
	a.first_enrollment_time > comp.first_enrollment_time
GROUP BY
	a.user_id,
	a.course_id;

DROP TABLE IF EXISTS ahemphill.p_verify_model_prior_enrolls_verifs;
CREATE TABLE IF NOT EXISTS ahemphill.p_verify_model_prior_enrolls_verifs AS 

SELECT
	a.user_id,
	a.course_id,
	COUNT(d_user_course.course_id) AS cnt_prior_enrolls,
    SUM(CASE WHEN year(d_user_course.first_enrollment_time) = '2017' THEN 1 ELSE 0 END) as cnt_2017_enrolls,
    SUM(CASE WHEN year(d_user_course.first_enrollment_time) = '2016' THEN 1 ELSE 0 END) as cnt_2016_enrolls,
    SUM(CASE WHEN year(d_user_course.first_enrollment_time) = '2015' THEN 1 ELSE 0 END) as cnt_2015_enrolls,
    COUNT(d_user_course.first_verified_enrollment_time) AS cnt_prior_verifs,
    SUM(CASE WHEN year(d_user_course.first_verified_enrollment_time) = '2016' THEN 1 ELSE 0 END) as cnt_2017_verifs,
    SUM(CASE WHEN year(d_user_course.first_verified_enrollment_time) = '2016' THEN 1 ELSE 0 END) as cnt_2016_verifs,
    SUM(CASE WHEN year(d_user_course.first_verified_enrollment_time) = '2015' THEN 1 ELSE 0 END) as cnt_2015_verifs
FROM
(
	SELECT 
		user_id, 
		course_id,
		first_enrollment_time
	FROM 
		ahemphill.p_verify_model
	GROUP BY
		user_id, 
		course_id,
		first_enrollment_time
) a
LEFT JOIN
	production.d_user_course d_user_course
ON
	a.user_id = d_user_course.user_id
AND
	a.first_enrollment_time > d_user_course.first_enrollment_time
GROUP BY
	a.user_id,
	a.course_id;

DROP TABLE IF EXISTS ahemphill.p_verify_model_master;
CREATE TABLE IF NOT EXISTS ahemphill.p_verify_model_master AS 
SELECT
	a.*,
	b.pacing_type,
	b.course_subject,
	b.course_run_number,
	b.course_partner,
	b.course_seat_price,
	stats_time.cum_sum_course_vtr,
	DATEDIFF('day', a.date, b.course_verification_end_date) AS days_until_verification_deadline,
	b.level_type,
	d_user.user_year_of_birth,
    d_user.user_level_of_education,
    d_user.user_gender,
    d_user.user_last_location_country_code,
    year(d_user.user_account_creation_time) AS year_registered,
    COALESCE(prior_passes.cnt_prior_passes, 0) AS cnt_prior_passes,
	COALESCE(prior_enrolls_verifs.cnt_prior_enrolls, 0) AS cnt_prior_enrolls,
	COALESCE(prior_enrolls_verifs.cnt_2017_enrolls, 0) AS cnt_2017_enrolls,
	COALESCE(prior_enrolls_verifs.cnt_2016_enrolls, 0) AS cnt_2016_enrolls,
	COALESCE(prior_enrolls_verifs.cnt_2015_enrolls, 0) AS cnt_2015_enrolls,
	COALESCE(prior_enrolls_verifs.cnt_prior_verifs, 0) AS cnt_prior_verifs,
	COALESCE(prior_enrolls_verifs.cnt_2017_verifs, 0) AS cnt_2017_verifs,
	COALESCE(prior_enrolls_verifs.cnt_2016_verifs, 0) AS cnt_2016_verifs,
	COALESCE(prior_enrolls_verifs.cnt_2015_verifs, 0) AS cnt_2015_verifs,
	SUM(a.is_active) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_is_active, 
	SUM(cnt_active_activity) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_cnt_active_activity, 
	SUM(is_engaged) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_is_engaged, 
	SUM(cnt_engaged_activity) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_cnt_engaged_activity,
	SUM(is_engaged_video) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_is_engaged_video, 
	SUM(cnt_video_activity) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_cnt_video_activity, 
	SUM(is_engaged_problem) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_is_engaged_problem, 
	SUM(cnt_problem_activity) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_cnt_problem_activity, 
	SUM(is_engaged_forum) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_is_engaged_forum,
	SUM(cnt_forum_activity) OVER (PARTITION BY a.user_id, a.course_id ORDER BY days_from_content_availability ASC) AS cumulative_cnt_forum_activity
FROM
	ahemphill.p_verify_model a
JOIN
	business_intelligence.course_master b
ON
	a.course_id = b.course_id
JOIN
	ahemphill.p_verify_model_prior_enrolls_verifs prior_enrolls_verifs
ON
	a.user_id = prior_enrolls_verifs.user_id
AND
	a.course_id = prior_enrolls_verifs.course_id
JOIN 
    production.d_user d_user
ON 
    a.user_id = d_user.user_id
JOIN
	ahemphill.p_verify_model_prior_completions prior_passes
ON 
    a.user_id = prior_passes.user_id
AND
	a.course_id = prior_passes.course_id
JOIN
	business_intelligence.course_stats_time stats_time
ON
	a.course_id = stats_time.course_id
AND
    a.date = stats_time.date;

---

DROP TABLE IF EXISTS ahemphill.p_verify_model_master_last_day;
CREATE TABLE IF NOT EXISTS ahemphill.p_verify_model_master_last_day AS 
SELECT
	MAX(date) AS latest_date,
	user_id,
	course_id,
	is_active,
	cnt_active_activity,
	is_engaged,
	cnt_engaged_activity,
	is_engaged_video,
	cnt_video_activity,
	is_engaged_problem,
	cnt_problem_activity,
	is_engaged_forum,
	cnt_forum_activity,
	weekly_engagement_level,
	first_enrollment_time,
	first_verified_enrollment_time,
	has_verified,
	days_from_content_availability,
	pacing_type,
	course_subject,
	course_run_number,
	course_partner,
	course_seat_price,
	cum_sum_course_vtr,
	days_until_verification_deadline,
	level_type,
	user_year_of_birth,
	user_level_of_education,
	user_gender,
	user_last_location_country_code,
	year_registered,
	cnt_prior_passes,
	cnt_prior_enrolls,
	cnt_2017_enrolls,
	cnt_2016_enrolls,
	cnt_2015_enrolls,
	cnt_prior_verifs,
	cnt_2017_verifs,
	cnt_2016_verifs,
	cnt_2015_verifs,
	cumulative_is_active,
	cumulative_cnt_active_activity,
	cumulative_is_engaged,
	cumulative_cnt_engaged_activity,
	cumulative_is_engaged_video,
	cumulative_cnt_video_activity,
	cumulative_is_engaged_problem,
	cumulative_cnt_problem_activity,
	cumulative_is_engaged_forum,
	cumulative_cnt_forum_activity
FROM
(
SELECT
	date,
	user_id,
	course_id,
	LAST_VALUE(is_active) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS is_active,
	LAST_VALUE(cnt_active_activity) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cnt_active_activity,
	LAST_VALUE(is_engaged) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS is_engaged,
	LAST_VALUE(cnt_engaged_activity) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cnt_engaged_activity,
	LAST_VALUE(is_engaged_video) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS is_engaged_video,
	LAST_VALUE(cnt_video_activity) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cnt_video_activity,
	LAST_VALUE(is_engaged_problem) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS is_engaged_problem,
	LAST_VALUE(cnt_problem_activity) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cnt_problem_activity,
	LAST_VALUE(is_engaged_forum) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS is_engaged_forum,
	LAST_VALUE(cnt_forum_activity) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cnt_forum_activity,
	LAST_VALUE(weekly_engagement_level) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS weekly_engagement_level,
	LAST_VALUE(first_enrollment_time) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS first_enrollment_time,
	LAST_VALUE(first_verified_enrollment_time) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS first_verified_enrollment_time,
	LAST_VALUE(has_verified) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS has_verified,
	LAST_VALUE(days_from_content_availability) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS days_from_content_availability,
	LAST_VALUE(pacing_type) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS pacing_type,
	LAST_VALUE(course_subject) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS course_subject,
	LAST_VALUE(course_run_number) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS course_run_number,
	LAST_VALUE(course_partner) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS course_partner,
	LAST_VALUE(course_seat_price) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS course_seat_price,
	LAST_VALUE(cum_sum_course_vtr) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cum_sum_course_vtr,
	LAST_VALUE(days_until_verification_deadline) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS days_until_verification_deadline,
	LAST_VALUE(level_type) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS level_type,
	LAST_VALUE(user_year_of_birth) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS user_year_of_birth,
	LAST_VALUE(user_level_of_education) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS user_level_of_education,
	LAST_VALUE(user_gender) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS user_gender,
	LAST_VALUE(user_last_location_country_code) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS user_last_location_country_code,
	LAST_VALUE(year_registered) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS year_registered,
	LAST_VALUE(cnt_prior_passes) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cnt_prior_passes,
	LAST_VALUE(cnt_prior_enrolls) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cnt_prior_enrolls,
	LAST_VALUE(cnt_2017_enrolls) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cnt_2017_enrolls,
	LAST_VALUE(cnt_2016_enrolls) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cnt_2016_enrolls,
	LAST_VALUE(cnt_2015_enrolls) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cnt_2015_enrolls,
	LAST_VALUE(cnt_prior_verifs) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cnt_prior_verifs,
	LAST_VALUE(cnt_2017_verifs) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cnt_2017_verifs,
	LAST_VALUE(cnt_2016_verifs) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cnt_2016_verifs,
	LAST_VALUE(cnt_2015_verifs) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cnt_2015_verifs,
	LAST_VALUE(cumulative_is_active) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cumulative_is_active,
	LAST_VALUE(cumulative_cnt_active_activity) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cumulative_cnt_active_activity,
	LAST_VALUE(cumulative_is_engaged) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cumulative_is_engaged,
	LAST_VALUE(cumulative_cnt_engaged_activity) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cumulative_cnt_engaged_activity,
	LAST_VALUE(cumulative_is_engaged_video) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cumulative_is_engaged_video,
	LAST_VALUE(cumulative_cnt_video_activity) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cumulative_cnt_video_activity,
	LAST_VALUE(cumulative_is_engaged_problem) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cumulative_is_engaged_problem,
	LAST_VALUE(cumulative_cnt_problem_activity) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cumulative_cnt_problem_activity,
	LAST_VALUE(cumulative_is_engaged_forum) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cumulative_is_engaged_forum,
	LAST_VALUE(cumulative_cnt_forum_activity) OVER (PARTITION BY user_id, course_id ORDER BY date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS cumulative_cnt_forum_activity
FROM
	ahemphill.p_verify_model_master
WHERE
	cumulative_is_active > 0
) a
GROUP BY 
	user_id,
	course_id,
	is_active,
	cnt_active_activity,
	is_engaged,
	cnt_engaged_activity,
	is_engaged_video,
	cnt_video_activity,
	is_engaged_problem,
	cnt_problem_activity,
	is_engaged_forum,
	cnt_forum_activity,
	weekly_engagement_level,
	first_enrollment_time,
	first_verified_enrollment_time,
	has_verified,
	days_from_content_availability,
	pacing_type,
	course_subject,
	course_run_number,
	course_partner,
	course_seat_price,
	cum_sum_course_vtr,
	days_until_verification_deadline,
	level_type,
	user_year_of_birth,
	user_level_of_education,
	user_gender,
	user_last_location_country_code,
	year_registered,
	cnt_prior_passes,
	cnt_prior_enrolls,
	cnt_2017_enrolls,
	cnt_2016_enrolls,
	cnt_2015_enrolls,
	cnt_prior_verifs,
	cnt_2017_verifs,
	cnt_2016_verifs,
	cnt_2015_verifs,
	cumulative_is_active,
	cumulative_cnt_active_activity,
	cumulative_is_engaged,
	cumulative_cnt_engaged_activity,
	cumulative_is_engaged_video,
	cumulative_cnt_video_activity,
	cumulative_is_engaged_problem,
	cumulative_cnt_problem_activity,
	cumulative_is_engaged_forum,
	cumulative_cnt_forum_activity

--
--understand what our baseline rate (no intervention) is based on the model

DROP TABLE ahemphill.baseline;
CREATE TABLE ahemphill.baseline(

latest_date	date,
user_id	int,
course_id	varchar(255),
has_verified	int,
pred_prob float

);

COPY ahemphill.baseline FROM LOCAL '/Users/adleyhemphill/baseline.csv' WITH DELIMITER ',';

select * FROM ahemphill.baseline;

select
pred_prob,
has_verified AS class,
COUNT(1) AS cnt_users,
SUM(CASE WHEN current_enrollment_mode = 'verified' THEN 1 ELSE 0 END) AS now_verified,
SUM(CASE WHEN current_enrollment_mode = 'verified' THEN 1 ELSE 0 END)*100.0/count(1)
from ahemphill.baseline a
join production.d_user_course b
on a.user_id = b.user_id
and a.course_id = b.course_id
group by 1,2
order by has_verified, pred_prob

--
--pull this weeks users

DROP TABLE ahemphill.eval;
CREATE TABLE ahemphill.eval(

latest_date	date,
user_id	int,
course_id	varchar(255),
has_verified	int,
pred_prob float

);

COPY ahemphill.eval FROM LOCAL '/Users/adleyhemphill/eval.csv' WITH DELIMITER ',';

select * FROM ahemphill.eval;

select
pred_prob,
has_verified AS class,
COUNT(1) AS cnt_users,
SUM(CASE WHEN current_enrollment_mode = 'verified' THEN 1 ELSE 0 END) AS now_verified,
SUM(CASE WHEN current_enrollment_mode = 'verified' THEN 1 ELSE 0 END)*100.0/count(1)
from ahemphill.eval a
join production.d_user_course b
on a.user_id = b.user_id
and a.course_id = b.course_id
group by 1,2
order by has_verified, pred_prob

--select * from columns where table_name = 'baseline'


SELECT 
	* 
FROM 
(
	SELECT
		CASE 
			WHEN cumulative_cnt_video_activity = 0 THEN 'no_activity'
			WHEN cumulative_cnt_video_activity between 1 and 5 THEN '1-5'
			WHEN cumulative_cnt_video_activity between 6 and 10 THEN '6-10'
			WHEN cumulative_cnt_video_activity >10  THEN '>10'
		END,
		'video' AS category,
		SUM(has_verified) * 100.0/COUNT(1) AS p_verify,
		COUNT(1) AS cnt_users
	FROM 
		ahemphill.p_verify_model_master
	WHERE 
		week IN ('week_1')
	GROUP BY
		1

	UNION ALL 

	SELECT
		CASE 
			WHEN cumulative_cnt_problem_activity = 0 THEN 'no_activity'
			WHEN cumulative_cnt_problem_activity between 1 and 5 THEN '1-5'
			WHEN cumulative_cnt_problem_activity between 6 and 10 THEN '6-10'
			WHEN cumulative_cnt_problem_activity >10  THEN '>10'
		END,
		'problem' AS category,
		SUM(has_verified) * 100.0/COUNT(1) AS p_verify,
		COUNT(1) AS cnt_users
	FROM 
		ahemphill.p_verify_model_master
	WHERE 
		week IN ('week_1')
	GROUP BY
		1

	UNION ALL

	SELECT
		CASE 
			WHEN cumulative_cnt_forum_activity = 0 THEN 'no_activity'
			WHEN cumulative_cnt_forum_activity between 1 and 5 THEN '1-5'
			WHEN cumulative_cnt_forum_activity between 6 and 10 THEN '6-10'
			WHEN cumulative_cnt_forum_activity >10  THEN '>10'
		END,
		'forum' AS category,
		SUM(has_verified) * 100.0/COUNT(1) AS p_verify,
		COUNT(1) AS cnt_users
	FROM 
		ahemphill.p_verify_model_master
	WHERE 
		week IN ('week_1')
	GROUP BY
		1
) a;

--agg number of users based on activity counts
SELECT
	cumulative_cnt_active_activity, 
	cumulative_cnt_engaged_activity,
	cumulative_cnt_video_activity, 
	cumulative_cnt_problem_activity, 
	cumulative_cnt_forum_activity,
	SUM(has_verified) AS cnt_verified,
	COUNT(1) AS cnt_users
FROM 
	ahemphill.p_verify_model_master
WHERE 
	week = 'week_1'
GROUP BY 
	cumulative_cnt_active_activity, 
	cumulative_cnt_engaged_activity,
	cumulative_cnt_video_activity, 
	cumulative_cnt_problem_activity, 
	cumulative_cnt_forum_activity;

--agg number of users based on days active/engaged
SELECT
	cumulative_is_active, 
	cumulative_is_engaged, 
	cumulative_is_engaged_video, 
	cumulative_is_engaged_problem, 
	cumulative_is_engaged_forum,
	SUM(has_verified) AS cnt_verified,
	COUNT(1) AS cnt_users
FROM 
	ahemphill.p_verify_model_master
WHERE 
	week IN ('week_1', 'week_2')
GROUP BY 
	cumulative_is_active, 
	cumulative_is_engaged, 
	cumulative_is_engaged_video, 
	cumulative_is_engaged_problem, 
	cumulative_is_engaged_forum


