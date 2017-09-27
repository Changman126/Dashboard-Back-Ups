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
    GROUP BY 1,2),
  experiment AS (
  SELECT
    a.fullVisitorId,
    IF(cd.value LIKE '%One_Click%',
      'Bundle',
      'Original') AS experiment_variation
  FROM
    `86300562.ga_sessions_*` a,
    UNNEST(customDimensions) AS cd,
    UNNEST(hits) AS h
  LEFT JOIN
    lms_users b
  ON
    a.fullVisitorId = b.fullVisitorId
  WHERE
    cd.index = 36
    AND _TABLE_SUFFIX BETWEEN '20170620'
    AND '20170627'
    AND b.user_id IS NULL
  GROUP BY
    1,
    2),
  experiment_trans AS (
  SELECT
    a.fullVisitorId,
    transaction.transactionId
  FROM
    `86300562.ga_sessions_*` a,
    UNNEST(hits) AS h
  LEFT JOIN
    lms_users b
  ON
    a.fullVisitorId = b.fullVisitorId
  WHERE
    _TABLE_SUFFIX BETWEEN '20170620'
    AND '20170627'
    AND transaction.transactionId IS NOT NULL
    AND b.user_id IS NULL
  GROUP BY
    1,
    2),
  enrollments AS (
  SELECT
    a.fullVisitorId,
    b.user_id,
    COUNT(h.eventInfo.eventLabel) AS cnt_enrollments
  FROM
    `86300562.ga_sessions_*` a,
    UNNEST(hits) AS h
  LEFT JOIN
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
    AND _TABLE_SUFFIX BETWEEN '20170620'
    AND '20170627'
    AND b.user_id IS NULL
  GROUP BY
    1,
    2 ),
  verifications AS (
  SELECT
    transaction.transactionId,
    MAX(transaction.transactionRevenue/1E6) AS bookings,
    COUNT(DISTINCT v2ProductName) AS cnt_verifications,
    CASE
      WHEN COUNT(DISTINCT v2ProductName) > 1 THEN 1
      ELSE 0
    END AS is_bundle
  FROM
    `86300562.ga_sessions_*`,
    UNNEST(hits) AS h,
    UNNEST(h.product) AS hp
  WHERE
    hp.v2ProductName IN ( 'course-v1:MichiganX+UX2+3T2016',
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
    AND _TABLE_SUFFIX BETWEEN '20170620'
    AND '20170627'
  GROUP BY
    1 ),
  no_user_id AS (
  SELECT
    IF(verifications.is_bundle = 1,
      'Bundle',
      experiment.experiment_variation) AS experiment_variation,
    experiment.fullVisitorId,
    verifications.bookings,
    COALESCE(enrollments.cnt_enrollments,
      verifications.cnt_verifications) AS cnt_enrollments,
    SUM(verifications.is_bundle) AS cnt_bundles,
    SUM(verifications.cnt_verifications) AS cnt_verifications
  FROM
    experiment
  LEFT JOIN
    experiment_trans
  USING
    (fullVisitorId)
  LEFT JOIN
    enrollments
  USING
    (fullVisitorId)
  LEFT JOIN
    verifications USING(transactionId)
  GROUP BY
    1,
    2,
    3,
    4 ),
  experiment_user_id AS (
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
    2 ),
    exposure_filtered AS (
  SELECT
    user_id,
    COUNT(DISTINCT experiment_variation)
  FROM
    experiment_user_id
    GROUP BY user_id
    HAVING 
    COUNT(DISTINCT experiment_variation) = 1),
  trans_user_id AS (
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
    2 ),
  enrollments_user_id AS (
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
    1 ),
  user_id AS (
  SELECT
    IF(trans.is_bundle = 1,
      'Bundle',
      experiment.experiment_variation) AS experiment_variation,
    experiment.user_id AS fullVisitorId,
    trans.bookings,
    COALESCE(enrollments.cnt_enrollments,
      trans.cnt_verifications) AS cnt_enrollments,
    SUM(trans.is_bundle) AS cnt_bundles,
    SUM(trans.cnt_verifications) AS cnt_verifications
  FROM
    experiment_user_id experiment
    JOIN
    exposure_filtered exposure_filtered
    USING(user_id)
  LEFT JOIN
    trans_user_id trans
  USING
    (user_id)
  LEFT JOIN
    enrollments_user_id enrollments
  USING
    (user_id)
  GROUP BY
    1,
    2,
    3,
    4 )

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
  SUM(cnt_bundles) AS cnt_bundles_purchased,
  SUM(cnt_verifications) AS sum_verifications,
  AVG(IF(cnt_verifications>0,
      cnt_verifications,
      NULL)) AS avg_verifications_per_verified_user,
  SUM(bookings) AS total_bookings
FROM
  (
    -- SELECT * FROM no_user_id
    -- UNION ALL
    SELECT * FROM user_id

)
GROUP BY
  1

---
--warehouse

SELECT
      variation_name,
      count(distinct a.user_id) AS cnt_users,
      count(b.course_id) AS cnt_enrollments
FROM 
(
      SELECT
            user_id,
            variation_name
      FROM
            optimizely_exposure_historical
      WHERE 
            experiment_name = 'Program Purchase Test with Discount Run 2'
      GROUP BY
            1,2
)
LEFT JOIN 
      production.d_user_course b
ON 
      a.user_id = b.user_id     
and 
      b.course_id IN ('course-v1:MichiganX+UX2+3T2016',
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
      and 
first_enrollment_time > first_exposure_timestamp


GROUP BY
  1;


  select

variation_name,
sum(transaction_amount_per_item)
FROM 
(
      SELECT
            user_id,
            first_exposure_timestamp,
            variation_name
      FROM
            ahemphill.optimizely_exposure_historical
      WHERE 
            experiment_name = 'Program Purchase Test with Discount Run 2'
      GROUP BY
            1,2,3
) a
JOIN 
production.d_user c
on a.user_id = c.user_id
 JOIN 
      finance.f_orderitem_transactions b
ON 
      c.user_username = b.order_username     
and 
      b.order_course_id IN ( 'course-v1:MichiganX+UX2+3T2016',
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
      and DATE(transaction_date) >= DATE(first_exposure_timestamp)-1
      and order_product_class = 'seat'
      group by 1
