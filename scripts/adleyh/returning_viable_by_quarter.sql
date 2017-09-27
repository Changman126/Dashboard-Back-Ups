SELECT
    first_touch,
    COUNT(username) AS cnt_viable_users
FROM
(
    SELECT
        username,
        MIN(year_month) as first_touch
    FROM
        curated.active_users_by_month
    WHERE
        year_month BETWEEN '2016-06' AND '2017-05'
    AND username NOT IN(
    SELECT
        user_username AS username
    FROM
        production.d_user
    WHERE
        user_account_creation_time >= '2016-06-01'
        AND user_account_creation_time < '2017-06-01'
        )
        group by 1
) a
group by 1