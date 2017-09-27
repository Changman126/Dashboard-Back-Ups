SELECT
  experiment_variation,
  COUNT(fullVisitorId) AS cnt_users,
  COUNTIF(cnt_enrollments>0) AS cnt_unique_users_enrolled,
  COUNTIF(cnt_enrollments>0) * 100.0/COUNT(fullVisitorId) AS pct_users_enrolled,
  SUM(cnt_enrollments) AS sum_enrollments,
  AVG(IF(cnt_enrollments>0,
      cnt_enrollments,
      NULL)) AS avg_enrollments_per_enrolled_user,
  COUNTIF(cnt_verifications>0) AS cnt_unique_users_verified,
  COUNTIF(cnt_verifications>0) * 100.0/COUNT(fullVisitorId) AS pct_users_verified,
  SUM(cnt_verifications) AS sum_verifications,
  AVG(IF(cnt_verifications>0,
      cnt_verifications,
      NULL)) AS avg_verifications_per_verified_user,
  SUM(revenue_usd) AS total_revenue,
  SUM(num_transactions) AS total_transactions
FROM (
  SELECT
    experiment.experiment_variation,
    experiment.fullVisitorId,
    revenue.revenue_usd,
    revenue.num_transactions,
    COUNT(enrollments.course_enrolled) AS cnt_enrollments,
    COUNT(verifications.course_verified) AS cnt_verifications
  FROM (
    SELECT
      fullVisitorId,
      cd.value AS experiment_variation
    FROM
      `86300562.ga_sessions_*`,
      UNNEST(customDimensions) AS cd,
      UNNEST(hits) AS h
    WHERE
      cd.index = 25
      AND _TABLE_SUFFIX > '20170602'
      --AND h.page.pagePath = '/'
    GROUP BY
      1,
      2) AS experiment
  LEFT JOIN (
    SELECT
      fullVisitorId,
      h.eventInfo.eventLabel AS course_enrolled
    FROM
      `86300562.ga_sessions_*`,
      UNNEST(hits) AS h
    WHERE
      h.eventInfo.eventAction = 'edx.course.enrollment.activated'
      AND _TABLE_SUFFIX > '20170602'
    GROUP BY
      1,
      2) AS enrollments
  ON
    experiment.fullVisitorId = enrollments.fullVisitorId
  LEFT JOIN (
    SELECT
      fullVisitorId,
      h.eventInfo.eventLabel AS course_verified
    FROM
      `86300562.ga_sessions_*`,
      UNNEST(hits) AS h
    WHERE
      h.eventInfo.eventAction = 'edx.course.enrollment.mode_changed'
      AND _TABLE_SUFFIX > '20170602'
    GROUP BY
      1,
      2 ) AS verifications
  ON
    experiment.fullVisitorId = verifications.fullVisitorId
    AND enrollments.course_enrolled = verifications.course_verified
  LEFT JOIN (
      SELECT
      fullVisitorId,
      COUNT(v2ProductCategory) AS num_transactions,
      SUM(hp.localProductPrice/1E6) AS revenue_usd
    FROM
      `86300562.ga_sessions_*`,
      UNNEST(hits) AS h,
      UNNEST(h.product) AS hp
    WHERE
     _TABLE_SUFFIX > '20170602'
    GROUP BY
      fullVisitorId ) AS revenue
  ON
    experiment.fullVisitorId = revenue.fullVisitorId
  GROUP BY
    1,
    2,
    3,
    4 )
GROUP BY
  1;

---

SELECT
  -- CASE
  --   WHEN totals.newVisits = 1 THEN 'new'
  --   ELSE 'returning'
  -- END AS new_vs_returning,
  cd.value,
  COUNT(DISTINCT a.fullVisitorId) AS cnt_users,
  SUM(cnt_enrollments) AS cnt_enrollments,
  COUNT(totals.bounces)*100.0/COUNT(totals.visits) AS bounce_rate,
  SUM(totals.transactions) AS cnt_transactions,
  SUM(totals.totalTransactionRevenue/1e6) AS sum_bookings
FROM
  `86300562.ga_sessions_*` a,
  UNNEST(customDimensions) AS cd,
  UNNEST(hits) AS h
LEFT JOIN (
  SELECT
    fullVisitorId,
    visitId,
    COUNT(h.eventInfo.eventLabel) AS cnt_enrollments
  FROM
    `86300562.ga_sessions_*`,
    UNNEST(hits) AS h
  WHERE
    h.eventInfo.eventAction = 'edx.course.enrollment.activated'
    AND _TABLE_SUFFIX > '20170601'
  GROUP BY
    1,
    2) AS enrollments
ON
  a.fullVisitorId = enrollments.fullVisitorId
  AND a.visitId = enrollments.visitId
WHERE
  _TABLE_SUFFIX > '20170601'
  AND cd.index = 25
  AND h.hitnumber = 1
  AND h.page.pagePath = '/'
GROUP BY
  1



