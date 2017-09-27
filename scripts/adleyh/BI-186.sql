--within session revenue per user

SELECT
  value,
  COUNT(DISTINCT fullVisitorId) AS cnt_users,
  COUNT(DISTINCT visitId) AS cnt_sessions,
  SUM(cnt_transactions) AS cnt_transactions,
  SUM(sum_bookings) AS sum_bookings,
  SUM(sum_bookings)/SUM(cnt_transactions) AS avg_transaction_amount,
  SUM(cnt_transactions) / COUNT(DISTINCT fullVisitorId) AS transactions_per_user,
  SUM(sum_bookings) / COUNT(DISTINCT fullVisitorId) AS bookings_per_user
FROM (
  SELECT
    cd.value,
    fullVisitorId,
    visitId,
    (totals.transactions) AS cnt_transactions,
    (totals.totalTransactionRevenue/1e6) AS sum_bookings
  FROM
    `86300562.ga_sessions_*` a,
    UNNEST(customDimensions) AS cd,
    UNNEST(hits) AS h
  WHERE
    cd.index = 31
    AND _TABLE_SUFFIX BETWEEN '20170614' AND '20170630'
  GROUP BY
    1,
    2,
    3,
    4,
    5 )
GROUP BY
  1


---overall revenue per user
SELECT
  a.value,
  COUNT(DISTINCT a.fullVisitorId) AS cnt_users,
  SUM(cnt_transactions) AS cnt_transactions,
  SUM(sum_bookings) AS sum_bookings,
  SUM(sum_bookings)/SUM(cnt_transactions) AS avg_transaction_amount,
  SUM(cnt_transactions) / COUNT(DISTINCT a.fullVisitorId) AS transactions_per_user,
  SUM(sum_bookings) / COUNT(DISTINCT a.fullVisitorId) AS bookings_per_user
FROM (
  SELECT
    cd.value,
    fullVisitorId,
    MIN(date) AS earliest_exposure_timestamp
  FROM
    `86300562.ga_sessions_*` a,
    UNNEST(customDimensions) AS cd,
    UNNEST(hits) AS h
  WHERE
    cd.index = 31
    AND _TABLE_SUFFIX >= '20170614'
  GROUP BY
    1,
    2) a
LEFT JOIN (
  SELECT
    date,
    fullVisitorId,
    COUNT(DISTINCT v2ProductName) AS cnt_transactions,
    SUM(hp.localProductPrice/1E6) AS sum_bookings
  FROM
    `86300562.ga_sessions_*`,
    UNNEST(hits) AS h,
    UNNEST(h.product) AS hp
  WHERE
    _TABLE_SUFFIX >= '20170614'
  GROUP BY
    date,
    fullVisitorId ) b
ON
  a.fullVisitorId = b.fullVisitorId
  AND b.date >= a.earliest_exposure_timestamp
GROUP BY
  1