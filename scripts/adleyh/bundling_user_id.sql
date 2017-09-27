WITH
  lms_users AS (
  SELECT
    fullVisitorId,
    cd.value AS user_id
  FROM
    `86300562.ga_sessions_*`,
    UNNEST(customDimensions) AS cd
  WHERE
    _TABLE_SUFFIX > '20170626'
    AND cd.index = 40
  GROUP BY 1,2)
  
SELECT
  experiment_variation,
  COUNT(user_id) AS cnt_users,
  COUNTIF(cnt_enrollments>0) AS cnt_unique_users_enrolled,
  COUNTIF(cnt_enrollments>0) * 100.0/COUNT(user_id) AS pct_users_enrolled,
  SUM(cnt_enrollments) AS sum_enrollments,
  AVG(IF(cnt_enrollments>0,
      cnt_enrollments,
      NULL)) AS avg_enrollments_per_enrolled_user,
  COUNTIF(cnt_verifications>0) AS cnt_unique_users_verified,
  COUNTIF(cnt_verifications>0) * 100.0/COUNT(user_id) AS pct_users_verified,
  SUM(cnt_bundles) AS cnt_bundles_purchased,
  SUM(cnt_verifications) AS sum_verifications,
  AVG(IF(cnt_verifications>0,
      cnt_verifications,
      NULL)) AS avg_verifications_per_verified_user,
  SUM(bookings) AS total_bookings
FROM (
  SELECT
    IF(trans.is_bundle = 1, 'Bundle', experiment.experiment_variation) AS experiment_variation,
    experiment.user_id,
    trans.bookings,
    COALESCE(enrollments.cnt_enrollments,
      trans.cnt_verifications) AS cnt_enrollments,
    SUM(trans.is_bundle) AS cnt_bundles,
    SUM(trans.cnt_verifications) AS cnt_verifications
  FROM (
    SELECT
      b.user_id,
      IF(cd.value LIKE '%One_Click%',
        'Bundle',
        'Original') AS experiment_variation
    FROM
      `86300562.ga_sessions_*` a,
      UNNEST(customDimensions) AS cd,
      UNNEST(hits) AS h
    JOIN
      lms_users b
    ON
      a.fullVisitorId = b.fullVisitorId
    WHERE
      cd.index = 36
      AND _TABLE_SUFFIX > '20170620'
    GROUP BY
      1,
      2) AS experiment
  LEFT JOIN (
SELECT
  b.user_id,
  transaction.transactionId,
  MAX(transaction.transactionRevenue/1E6) AS bookings,
  COUNT(DISTINCT v2ProductName) AS cnt_verifications,
  CASE
    WHEN COUNT(DISTINCT v2ProductName) > 1 THEN 1
    ELSE 0
  END AS is_bundle
FROM
  `86300562.ga_sessions_*` a,
  UNNEST(hits) AS h,
  UNNEST(h.product) AS hp
JOIN
  lms_users b
ON
  a.fullVisitorId = b.fullVisitorId
WHERE
  _TABLE_SUFFIX > '20170620'
  AND transaction.transactionId IS NOT NULL
  AND hp.v2ProductName IN ( 'course-v1:MichiganX+UX2+3T2016',
    'course-v1:MichiganX+UX3+3T2016',
    'course-v1:MichiganX+UX501x+3T2016',
    'course-v1:MichiganX+UX504x+1T2017',
    'course-v1:MichiganX+UX509x+2T2017',
    'course-v1:MichiganX+UXD5+1T2017',
    'course-v1:MichiganX+UXD6+1T2017',
    'course-v1:MichiganX+UXR5+1T2017',
    'course-v1:MichiganX+UXR6+1T2017',
    'course-v1:UCSanDiegoX+DS220x+1T2018',
    'course-v1:UCSanDiegoX+DSE200x+2T2017',
    'course-v1:UCSanDiegoX+DSE210x+3T2017',
    'course-v1:UCSanDiegoX+DSE230x+1T2018',
    'course-v1:UBCx+HtC1x+2T2017',
    'course-v1:UBCx+HtC2x+2T2017',
    'course-v1:UBCx+SoftConst1x+3T2017',
    'course-v1:UBCx+SoftConst2x+3T2017',
    'course-v1:UBCx+SoftEng1x+1T2018',
    'course-v1:UBCx+SoftEngPrjx+1T2018',
    'course-v1:UBCx+SPD2x+2T2015',
    'course-v1:UBCx+SPD2x+2T2016',
    'course-v1:UBCx+SPD3x+2T2016',
    'course-v1:UBCx+SPD3x+3T2015',
    'course-v1:W3Cx+CSS.0x+1T2016',
    'course-v1:W3Cx+CSS.0x+1T2017',
    'course-v1:W3Cx+HTML5.0x+1T2016',
    'course-v1:W3Cx+HTML5.0x+1T2017',
    'course-v1:W3Cx+HTML5.0x+2T2016',
    'course-v1:W3Cx+HTML5.0x+2T_2016',
    'course-v1:W3Cx+HTML5.1x+1T2017',
    'course-v1:W3Cx+HTML5.1x+2T2016',
    'course-v1:W3Cx+HTML5.1x+3T2016',
    'course-v1:W3Cx+HTML5.1x+4T2015',
    'course-v1:W3Cx+HTML5.2x+1T2016',
    'course-v1:W3Cx+HTML5.2x+1T2017',
    'course-v1:W3Cx+HTML5.2x+2T2016',
    'course-v1:W3Cx+HTML5.2x+3T2017',
    'course-v1:W3Cx+HTML5.2x+4T2015',
    'course-v1:W3Cx+JS.0x+1T2017',
    'course-v1:W3Cx+W3C-HTML5+2015T3',
    'course-v1:PennX+ROBO1x+1T2017',
    'course-v1:PennX+ROBO2x+2T2017',
    'course-v1:PennX+ROBO3x+2T2017',
    'course-v1:PennX+ROBO4x+3T2017' )
  AND eventInfo.eventCategory = 'EnhancedEcommerce'
  AND eventInfo.eventAction = 'Order Completed'
  AND eventInfo.eventLabel = 'event'
GROUP BY
  1,
  2
) AS trans
  ON
    experiment.user_id = trans.user_id
  LEFT JOIN (
    SELECT
      b.user_id,
      COUNT(DISTINCT h.eventInfo.eventLabel) AS cnt_enrollments
    FROM
      `86300562.ga_sessions_*` a,
      UNNEST(hits) AS h
    JOIN
      lms_users b
    ON
      a.fullVisitorId = b.fullVisitorId
    WHERE
      h.eventInfo.eventAction = 'edx.course.enrollment.activated'
      AND h.eventInfo.eventLabel IN ('course-v1:MichiganX+UX2+3T2016',
        'course-v1:MichiganX+UX3+3T2016',
        'course-v1:MichiganX+UX501x+3T2016',
        'course-v1:MichiganX+UX504x+1T2017',
        'course-v1:MichiganX+UX509x+2T2017',
        'course-v1:MichiganX+UXD5+1T2017',
        'course-v1:MichiganX+UXD6+1T2017',
        'course-v1:MichiganX+UXR5+1T2017',
        'course-v1:MichiganX+UXR6+1T2017',
        'course-v1:UCSanDiegoX+DS220x+1T2018',
        'course-v1:UCSanDiegoX+DSE200x+2T2017',
        'course-v1:UCSanDiegoX+DSE210x+3T2017',
        'course-v1:UCSanDiegoX+DSE230x+1T2018',
        'course-v1:UBCx+HtC1x+2T2017',
        'course-v1:UBCx+HtC2x+2T2017',
        'course-v1:UBCx+SoftConst1x+3T2017',
        'course-v1:UBCx+SoftConst2x+3T2017',
        'course-v1:UBCx+SoftEng1x+1T2018',
        'course-v1:UBCx+SoftEngPrjx+1T2018',
        'course-v1:UBCx+SPD2x+2T2015',
        'course-v1:UBCx+SPD2x+2T2016',
        'course-v1:UBCx+SPD3x+2T2016',
        'course-v1:UBCx+SPD3x+3T2015',
        'course-v1:W3Cx+CSS.0x+1T2016',
        'course-v1:W3Cx+CSS.0x+1T2017',
        'course-v1:W3Cx+HTML5.0x+1T2016',
        'course-v1:W3Cx+HTML5.0x+1T2017',
        'course-v1:W3Cx+HTML5.0x+2T2016',
        'course-v1:W3Cx+HTML5.0x+2T_2016',
        'course-v1:W3Cx+HTML5.1x+1T2017',
        'course-v1:W3Cx+HTML5.1x+2T2016',
        'course-v1:W3Cx+HTML5.1x+3T2016',
        'course-v1:W3Cx+HTML5.1x+4T2015',
        'course-v1:W3Cx+HTML5.2x+1T2016',
        'course-v1:W3Cx+HTML5.2x+1T2017',
        'course-v1:W3Cx+HTML5.2x+2T2016',
        'course-v1:W3Cx+HTML5.2x+3T2017',
        'course-v1:W3Cx+HTML5.2x+4T2015',
        'course-v1:W3Cx+JS.0x+1T2017',
        'course-v1:W3Cx+W3C-HTML5+2015T3',
        'course-v1:PennX+ROBO1x+1T2017',
        'course-v1:PennX+ROBO2x+2T2017',
        'course-v1:PennX+ROBO3x+2T2017',
        'course-v1:PennX+ROBO4x+3T2017' )
      AND _TABLE_SUFFIX > '20170620'
    GROUP BY
      1) AS enrollments
  ON
    experiment.user_id = enrollments.user_id
  GROUP BY
    1,
    2,
    3,
    4 )
GROUP BY
  1