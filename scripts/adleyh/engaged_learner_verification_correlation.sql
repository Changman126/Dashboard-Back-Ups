--2967054
select
	CASE WHEN min_verified_date is not null then 'verified' else 'not verified' end as verified,
	CASE WHEN min_verified_date IS NOT NULL THEN days_engaged_prior_verif ELSE days_engaged end AS days_engaged_adj,
	count(distinct a.user_id) AS cnt_users
FROM
(
	SELECT
		a.user_id,
		min_verified_date,
		COUNT(DISTINCT date) AS days_engaged,
		SUM(CASE WHEN date <= min_verified_date THEN 1 ELSE 0 END) AS days_engaged_prior_verif


	FROM
	(
		select user_id, date
		from production.f_user_activity
		where activity_type != 'ACTIVE'
		group by 1,2
	) a
	left join 
	(
		select user_id, MIN(date(first_verified_enrollment_time)) AS min_verified_date
		from production.d_user_course
		where first_verified_enrollment_time is not null
		and date(first_verified_enrollment_time) > '2016-03-21'
		group by 1
	) b 
	on a.user_id = b.user_id
	join
	(
					SELECT
				user_id
			FROM
				production.d_user
			WHERE
			      user_account_creation_time >= '2016-04-01'


			      ) c
	ON a.user_id = c.user_id
	GROUP BY 1,2
) a
group by 
	1,2

