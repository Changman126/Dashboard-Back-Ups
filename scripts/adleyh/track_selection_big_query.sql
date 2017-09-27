  SELECT
    --fullVisitorId,
    customDimensions.value,
    sum(totals.pageviews) AS pageviews,
    sum(totals.transactions) AS transactions,
    sum(totals.transactionRevenue/1E6) AS amount_usd
  FROM
    [86300562.ga_sessions_20170524]
  WHERE
    customDimensions.index = 18
    AND date = '20170524'
    AND customDimensions.value LIKE '%Production%'
    AND customDimensions.value NOT LIKE '%holdback%'
   group by 1

     SELECT
    fullVisitorId,
    customDimensions.value,
    totals.transactionRevenue/1E6 AS amount_usd,
    sum(totals.transactions),
    count(1)
  FROM
    [86300562.ga_sessions_20170524]
  WHERE
    customDimensions.index = 18
    AND date = '20170524'
    AND customDimensions.value LIKE '%Production%'
    AND customDimensions.value NOT LIKE '%holdback%'
    and totals.transactionRevenue is not null
   group by 1,2,3


   EDX-21669954

     SELECT
    fullVisitorId,
    hits.page.pagePath,
    hits.time
  FROM
    [86300562.ga_sessions_20170524]
  WHERE
    fullVisitorId = '2017466751697305577'
    and hits.page.pagePath is not null
    order by hits.time asc

         SELECT
    fullVisitorId,
    customDimensions.value,
    totals.transactionRevenue/1E6 AS amount_usd,
    sum(totals.transactions) AS transactions,
    count(1) AS goal_completions
  FROM
    [86300562.ga_sessions_20170524]
  WHERE
    customDimensions.index = 18
    AND date = '20170524'
    AND customDimensions.value LIKE '%Production%'
    AND customDimensions.value NOT LIKE '%holdback%'
    and totals.transactionRevenue is not null
   group by 1,2,3

   SELECT
  date,
  customDimensions.value,
  COUNT(fullVisitorId) AS cnt_users,
  SUM(totals.pageviews) AS total_pageviews,
  SUM(totals.transactions) AS total_transactions,
  COUNT(totals.transactions) AS goal_12_completions,
  SUM(totals.transactionRevenue/1E6) AS amount_usd
FROM
  [86300562.ga_sessions_intraday_20170525],
  [86300562.ga_sessions_20170524]
WHERE
  customDimensions.index = 18
  AND date >= '20170524'
  AND customDimensions.value LIKE '%Production%'
  AND customDimensions.value NOT LIKE '%holdback%'
GROUP BY
  1,
  2