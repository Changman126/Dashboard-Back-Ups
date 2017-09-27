SELECT
  b.date,
  course_id,
  COUNT(1) AS cnt_enrolls
FROM
(
    SELECT
    a.fullVisitorId,
    a.visitId,
    h.eventInfo.eventLabel AS course_id
  FROM
    `86300562.ga_sessions_*` a,
    UNNEST(hits) AS h
  WHERE
    h.eventInfo.eventAction = 'edx.course.enrollment.activated'
    AND _TABLE_SUFFIX  > '20170101'
  GROUP BY
    1,
    2,
    3

) a
JOIN
(
SELECT
  date,
  fullVisitorId,
  visitId
FROM
  `86300562.ga_sessions_*` a,
  UNNEST(customDimensions) AS cd,
  UNNEST(hits) AS h
WHERE
  channelGrouping = 'Affiliate'
  AND trafficSource.source LIKE '%Fair%'
  AND _TABLE_SUFFIX > '20170101'
GROUP BY
  1,
  2,
  3
) B
ON 
  a.visitId = b.visitId
GROUP BY 
  1,2