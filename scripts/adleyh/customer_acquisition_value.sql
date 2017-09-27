--by reg year

SELECT
fiscal_year,
count(1) as cnt_users,
avg(cnt_enrolls) AS avg_enrolls_per_user,
avg(cnt_verifs) AS avg_verifs_per_user,
avg(case when cnt_enrolls = 0 THEN 0 ELSE cnt_verifs*100.0/cnt_enrolls END) AS avg_verif_rate_per_user

FROM
(
SELECT
CASE
WHEN DATE(user_account_creation_time) BETWEEN '2016-04-20' AND '2017-04-20' THEN 'this_year'
WHEN DATE(user_account_creation_time) BETWEEN '2015-04-20' AND '2016-04-20' THEN 'last_year'
WHEN DATE(user_account_creation_time) BETWEEN '2014-04-20' AND '2015-04-20' THEN 'two_years_ago'
END AS fiscal_year,
a.user_id,
COUNT(b.course_id) AS cnt_enrolls,
COUNT(first_verified_enrollment_time) AS cnt_verifs
FROM 
production.d_user a
left JOIN production.d_user_course b
ON a.user_id = b.user_id
WHERE DATE(user_account_creation_time) >= '2014-04-20'
GROUP BY 1,2
) a 
group by 1


--by enrollment year
SELECT
fiscal_year,
count(1) as cnt_users,
avg(cnt_enrolls) AS avg_enrolls_per_user,
avg(cnt_verifs) AS avg_verifs_per_user,
avg(case when cnt_enrolls = 0 THEN 0 ELSE cnt_verifs*100.0/cnt_enrolls END) AS avg_verif_rate_per_user

FROM
(
SELECT
CASE
WHEN DATE(first_enrollment_time) BETWEEN '2016-04-20' AND '2017-04-20' THEN 'this_year'
WHEN DATE(first_enrollment_time) BETWEEN '2015-04-20' AND '2016-04-20' THEN 'last_year'
WHEN DATE(first_enrollment_time) BETWEEN '2014-04-20' AND '2015-04-20' THEN 'two_years_ago'
END AS fiscal_year,
b.user_id,
COUNT(1) AS cnt_enrolls,
COUNT(first_verified_enrollment_time) AS cnt_verifs
FROM 
 production.d_user_course b
GROUP BY 1,2
) a 
group by 1