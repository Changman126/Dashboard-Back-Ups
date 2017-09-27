DROP TABLE IF EXISTS ahemphill.utm_first_last_touch_stg;
CREATE TABLE IF NOT EXISTS ahemphill.utm_first_last_touch_stg AS

SELECT
	*
FROM
(
	SELECT
		user_id,
		utm_touch_timestamp,
		user_account_creation_time,
		campaign_source,
		campaign_medium,
		campaign_content,
		campaign_name,
		'first_touch' AS attribution_model
	FROM
	(
		SELECT
			a.user_id,
			timestamp AS utm_touch_timestamp,
			a.user_account_creation_time,
			campaign_source,
			campaign_medium,
			campaign_content,
			campaign_name,
			row_number() OVER (partition by a.user_id order by timestamp ASC) AS rank
		FROM 
			production.d_user a
		JOIN 
			utm_touch b
		ON 
			cast(a.user_id as varchar) = cast(b.user_id as varchar)
		AND 
			a.user_account_creation_time >= '2017-01-01'
		AND
			timestamp < a.user_account_creation_time
	) a
	WHERE 
		rank = 1

	UNION ALL

	SELECT
		user_id,
		utm_touch_timestamp,
		user_account_creation_time,
		campaign_source,
		campaign_medium,
		campaign_content,
		campaign_name,
		'last_touch' AS attribution_model
	FROM
	(
		SELECT
			a.user_id,
			timestamp AS utm_touch_timestamp,
			a.user_account_creation_time,
			campaign_source,
			campaign_medium,
			campaign_content,
			campaign_name,
			row_number() OVER (partition by a.user_id order by timestamp DESC) AS rank
		FROM 
			production.d_user a
		JOIN 
			utm_touch b
		ON 
			cast(a.user_id as varchar) = cast(b.user_id as varchar)
		AND 
			a.user_account_creation_time >= '2017-01-01'
		AND
			timestamp < a.user_account_creation_time
	) a
	WHERE 
		rank = 1
) a;

DROP TABLE IF EXISTS ahemphill.utm_first_last_touch;
CREATE TABLE IF NOT EXISTS ahemphill.utm_first_last_touch AS

SELECT
	a.*,
	COALESCE(b.cnt_enrolls, 0) AS cnt_enrolls,
	COALESCE(b.cnt_verifs, 0) AS cnt_verifs,
	COALESCE(c.sum_transactions, 0) AS sum_transactions
FROM
	ahemphill.utm_first_last_touch_stg a
LEFT JOIN
(
	SELECT
		user_id,
		COUNT(1) AS cnt_enrolls,
		COUNT(first_verified_enrollment_time) AS cnt_verifs
	FROM
		production.d_user_course
	GROUP BY
		user_id
) b
ON
	a.user_id = b.user_id
LEFT JOIN
(
	SELECT
		user_id,
		SUM(transaction_amount_per_item) AS sum_transactions
	FROM
		finance.f_orderitem_transactions a
	JOIN
		production.d_user b
	ON
		a.order_username = b.user_username
	GROUP BY
		user_id
) c
ON
	a.user_id = c.user_id;

DROP TABLE IF EXISTS ahemphill.utm_first_last_touch_summary;
CREATE TABLE IF NOT EXISTS ahemphill.utm_first_last_touch_summary AS

SELECT
	attribution_model,
	MONTH(utm_touch_timestamp) AS month,
	campaign_medium,
	campaign_source,
	campaign_name,
	campaign_content,
	COUNT(distinct user_id) AS cnt_users,
	SUM(cnt_enrolls) AS cnt_enrolls,
	SUM(sum_transactions) AS sum_transactions
FROM 
	ahemphill.utm_first_last_touch
WHERE 
	attribution_model = 'first_touch'
GROUP BY
	attribution_model,
	MONTH(utm_touch_timestamp),
	campaign_medium,
	campaign_source,
	campaign_name,
	campaign_content;