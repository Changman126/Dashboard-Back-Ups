SELECT
	course_id,
	course_number,
	course_partner,
	course_subject,
	course_start_date,
	course_end_date,
	course_verification_end_date,
	days_between_verification_deadline_and_course_end,
	CASE
		WHEN abs(days_between_verification_deadline_and_course_end) = 0 THEN '0'
		WHEN abs(days_between_verification_deadline_and_course_end) BETWEEN 1 AND 6 THEN '1d-7d'
		WHEN abs(days_between_verification_deadline_and_course_end) BETWEEN 7 AND 13 THEN '7d-14d'
		WHEN abs(days_between_verification_deadline_and_course_end) BETWEEN 14 AND 29 THEN '14d-30d'
		WHEN abs(days_between_verification_deadline_and_course_end) > 29 THEN '>30d'
	END AS days_between_verification_deadline_and_course_end_group,
	MAX(cum_sum_enrolls) AS final_enroll_count, 
	MAX(cum_sum_verifications) AS final_verification_count,
	MAX(vtr) AS final_vtr,
	SUM(
		CASE
			WHEN days_from_verification_deadline = 0 THEN cnt_verifications
			ELSE 0
		END) AS cnt_verifications_final_day,
	SUM(
		CASE
			WHEN days_from_verification_deadline BETWEEN -1 AND 0 THEN cnt_verifications
			ELSE 0
		END) AS cnt_verifications_final_two_days,
	SUM(
		CASE
			WHEN days_from_verification_deadline BETWEEN -2 AND 0 THEN cnt_verifications
			ELSE 0
		END) AS cnt_verifications_final_three_day,
	SUM(
		CASE
			WHEN days_from_verification_deadline BETWEEN -6 AND 0 THEN cnt_verifications
			ELSE 0
		END) AS cnt_verifications_final_seven_day

FROM
(
	SELECT
		a.course_id,
		a.course_number,
		course_partner,
		course_subject,
		course_start_date,
		course_end_date,
		course_verification_end_date,
		DATEDIFF('day', course_end_date, course_verification_end_date) AS days_between_verification_deadline_and_course_end,
		DATEDIFF('day', course_verification_end_date, b.date) AS days_from_verification_deadline,
		cnt_verifications,
		cum_sum_verifications,
		cnt_enrolls,
		cum_sum_enrolls,
		cum_sum_course_vtr * 100.0 AS vtr
	FROM 
		business_intelligence.course_master a
	JOIN 
		business_intelligence.course_stats_time b
	ON 
		a.course_id = b.course_id
	AND 
		course_end_date is not null
	AND 
		course_verification_end_Date is not null
	AND 
		pacing_type = 'instructor_paced'
	AND 
		b.date BETWEEN DATE(course_verification_end_date) - 7 AND DATE(course_verification_end_date)
) a
GROUP BY
	course_id,
	course_number,
	course_partner,
	course_subject,
	course_start_date,
	course_end_date,
	course_verification_end_date,
	days_between_verification_deadline_and_course_end,
	8