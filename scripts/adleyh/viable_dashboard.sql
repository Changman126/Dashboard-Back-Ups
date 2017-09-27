--with country

SELECT
  COALESCE(traffic_reg.date, enrollments.date) AS date,
  COALESCE(traffic_reg.channelGrouping, enrollments.channelGrouping) AS channelGrouping,
  COALESCE(traffic_reg.trafficSource_campaign, enrollments.trafficSource_campaign) AS trafficSource_campaign,
  CASE
    WHEN traffic_reg.country = 'United States' THEN traffic_reg.country
    WHEN traffic_reg.country = 'India' THEN traffic_reg.country
    WHEN traffic_reg.country = 'Brazil' THEN traffic_reg.country 
    WHEN traffic_reg.country = 'United Kingdom' THEN traffic_reg.country 
    WHEN traffic_reg.country = 'Egypt' THEN traffic_reg.country 
    WHEN traffic_reg.country = 'Canada' THEN traffic_reg.country 
    WHEN traffic_reg.country = 'Australia' THEN traffic_reg.country
    WHEN traffic_reg.country = 'Germany' THEN traffic_reg.country
    WHEN traffic_reg.country = 'China' THEN traffic_reg.country
  WHEN traffic_reg.country = 'Nigeria' THEN traffic_reg.country
  WHEN traffic_reg.country = 'Netherlands' THEN traffic_reg.country
    WHEN traffic_reg.country IN
    (
      'Argentina',
      'Bolivia',
      'Chile',
      'Colombia',
      'Costa Rica',
      'Cuba',
      'Dominican Republic',
      'Ecuador',
      'El Salvador',
      'Guatemala',
      'Honduras',
      'Mexico',
      'Nicaragua',
      'Panama',
      'Paraguay',
      'Peru',
      'Puerto Rico',
      'Spain',
      'Uruguay',
      'Venezuela'
      ) THEN 'spanish_speaking_countries'
    ELSE 'other'
    END AS country_grouping,
  cnt_users,
  cnt_sessions,
  cnt_registrations,
  cnt_enrollments
FROM (
  SELECT
    COALESCE(traffic.date, registrations.date) AS date,
    COALESCE(traffic.channelGrouping, registrations.channelGrouping) AS channelGrouping,
    COALESCE(traffic.trafficSource_campaign, registrations.trafficSource_campaign) AS trafficSource_campaign,
    traffic.country AS country,
    cnt_users,
    cnt_sessions,
    cnt_registrations
  FROM (
    SELECT
      CAST(date AS STRING) AS date,
      geoNetwork.country AS country,
      COALESCE(trafficSource.campaign, 'none') AS trafficSource_campaign,
      channelGrouping,
      COUNT(DISTINCT fullVisitorId) AS cnt_users,
      COUNT(DISTINCT visitId) AS cnt_sessions
    FROM
      TABLE_DATE_RANGE([86300562.ga_sessions_], TIMESTAMP('2017-01-01'), TIMESTAMP('2018-01-01'))
    GROUP BY
      date,
      channelGrouping,
      country,
      trafficSource_campaign) traffic
  FULL OUTER JOIN EACH (
    SELECT
      CAST(date AS STRING) AS date,
      geoNetwork.country AS country,
      COALESCE(trafficSource.campaign, 'none') AS trafficSource_campaign,
      channelGrouping,
      COUNT(DISTINCT fullVisitorId) AS cnt_registrations
    FROM
      TABLE_DATE_RANGE([86300562.ga_sessions_], TIMESTAMP('2017-01-01'), TIMESTAMP('2018-01-01'))
    WHERE
      hits.eventInfo.eventAction = 'edx.bi.user.account.registered'
    GROUP BY
      date,
      channelGrouping,
      country,
      trafficSource_campaign ) registrations
  ON
    traffic.date = registrations.date
    AND traffic.channelGrouping = registrations.channelGrouping
    AND traffic.country = registrations.country
    AND traffic.trafficSource_campaign = registrations.trafficSource_campaign ) traffic_reg
FULL OUTER JOIN EACH (
  SELECT
    CAST(date AS STRING) AS date,
    geoNetwork.country AS country,
    COALESCE(trafficSource.campaign, 'none') AS trafficSource_campaign,
    channelGrouping,
    COUNT(hits.eventInfo.eventLabel) AS cnt_enrollments
  FROM
    TABLE_DATE_RANGE([86300562.ga_sessions_], TIMESTAMP('2017-01-01'), TIMESTAMP('2018-01-01'))
  WHERE
    hits.eventInfo.eventAction = 'edx.course.enrollment.activated'
  GROUP BY
    date,
    channelGrouping,
    country,
    trafficSource_campaign ) enrollments
ON
  traffic_reg.date = enrollments.date
  AND traffic_reg.channelGrouping = enrollments.channelGrouping
  AND traffic_reg.country = enrollments.country
  AND traffic_reg.trafficSource_campaign = enrollments.trafficSource_campaign

--returning viable

SELECT
  CAST(date AS STRING) AS date,
  CASE
    WHEN country = 'United States' THEN country
    WHEN country = 'India' THEN country
    WHEN country = 'Brazil' THEN country
    WHEN country = 'United Kingdom' THEN country
    WHEN country = 'Egypt' THEN country
    WHEN country = 'Canada' THEN country
    WHEN country = 'Australia' THEN country
    WHEN country = 'Germany' THEN country
    WHEN country = 'China' THEN country
    WHEN country = 'Nigeria' THEN country
    WHEN country = 'Netherlands' THEN country
    WHEN country IN ( 'Argentina',
    'Bolivia',
    'Chile',
    'Colombia',
    'Costa Rica',
    'Cuba',
    'Dominican Republic',
    'Ecuador',
    'El Salvador',
    'Guatemala',
    'Honduras',
    'Mexico',
    'Nicaragua',
    'Panama',
    'Paraguay',
    'Peru',
    'Puerto Rico',
    'Spain',
    'Uruguay',
    'Venezuela' ) THEN 'spanish_speaking_countries'
    ELSE 'other'
  END AS country_grouping,
  trafficSource_campaign,
  channelGrouping,
  COUNT(DISTINCT user_id) AS cnt_returning_viable_users
FROM (
  SELECT
    user_id,
    FIRST_VALUE(country) OVER (PARTITION BY user_id ORDER BY DATE ASC) AS country,
    FIRST_VALUE(date) OVER (PARTITION BY user_id ORDER BY DATE ASC) AS date,
    FIRST_VALUE(trafficSource_campaign) OVER (PARTITION BY user_id ORDER BY DATE ASC) AS trafficSource_campaign,
    FIRST_VALUE(channelGrouping) OVER (PARTITION BY user_id ORDER BY DATE ASC) AS channelGrouping
  FROM (
    SELECT
      date,
      fullVisitorId,
      customDimensions.value AS user_id,
      geoNetwork.country AS country,
      COALESCE(trafficSource.campaign, 'none') AS trafficSource_campaign,
      channelGrouping
    FROM
      TABLE_DATE_RANGE([86300562.ga_sessions_], TIMESTAMP('2017-07-01'), TIMESTAMP('2018-01-01'))
    WHERE
      customDimensions.index = 40
    GROUP BY
      1,
      2,
      3,
      4,
      5,
      6) a
  WHERE
    fullVisitorId NOT IN (
    SELECT
      fullVisitorId
    FROM
      TABLE_DATE_RANGE([86300562.ga_sessions_], TIMESTAMP('2017-07-01'), TIMESTAMP('2018-01-01'))
    WHERE
      hits.eventInfo.eventAction = 'edx.bi.user.account.registered' )
  GROUP BY
    1,
    2,
    3,
    4,
    5 ) a
GROUP BY
  1,
  2,
  3,
  4