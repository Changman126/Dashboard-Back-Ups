# query = """

# --overall experiment data

# WITH
#   lms_users AS (
#   SELECT
#     fullVisitorId,
#     cd.value AS user_id
#   FROM
#     `86300562.ga_sessions_*`,
#     UNNEST(customDimensions) AS cd
#   WHERE
#     _TABLE_SUFFIX >= '20170628'
#     AND cd.index = 40
#     ),
#   exposure AS (
#   SELECT
#     user_id,
#     cd.value AS variation,
#     MIN(date) AS first_exposure_date
#   FROM
#     `86300562.ga_sessions_*` a,
#     UNNEST(customDimensions) AS cd,
#     UNNEST(hits) AS h
#   JOIN
#     lms_users b
#   ON
#     a.fullVisitorId = b.fullVisitorId
#   WHERE
#     cd.index = {EXPERIMENT_CUSTOM_DIMENSION}
#     AND _TABLE_SUFFIX BETWEEN '{EXPERIMENT_START_DATE}' AND '{EXPERIMENT_END_DATE}'
#   GROUP BY
#     1,
#     2),
#   exposure_filtered AS (
#   SELECT
#     user_id,
#     COUNT(DISTINCT variation)
#   FROM
#     exposure
#     GROUP BY user_id
#     HAVING 
#     COUNT(DISTINCT variation) = 1),
#   enrollments AS (
#     SELECT
#     date,
#     b.user_id,
#     h.eventInfo.eventLabel AS course_id
#   FROM
#     `86300562.ga_sessions_*` a,
#     UNNEST(hits) AS h
#   LEFT JOIN
#     lms_users b
#   ON
#     a.fullVisitorId = b.fullVisitorId
#   WHERE
#     h.eventInfo.eventAction = 'edx.course.enrollment.activated'
#     AND REGEXP_CONTAINS(h.eventInfo.eventLabel, r'{COURSE_ENROLLMENT_REGEXP}')
#     AND _TABLE_SUFFIX BETWEEN '{EXPERIMENT_START_DATE}' AND '{EXPERIMENT_END_DATE}'
#   GROUP BY
#     1,
#     2,
#     3),
#     transactions AS (
#   SELECT
#     date,
#     b.user_id,
#     transaction.transactionId,
#     transaction.transactionRevenue/1E6 AS bookings_usd,
#     v2ProductName AS course_id
#   FROM
#     `86300562.ga_sessions_*` a,
#     UNNEST(hits) AS h,
#     UNNEST(h.product) AS hp
#   JOIN
#     lms_users b
#   ON
#     a.fullVisitorId = b.fullVisitorId
#   WHERE
#     transaction.transactionId IS NOT NULL
#     AND REGEXP_CONTAINS(hp.v2ProductName, r'{COURSE_ENROLLMENT_REGEXP}')
#     AND _TABLE_SUFFIX BETWEEN '{EXPERIMENT_START_DATE}' AND '{EXPERIMENT_END_DATE}'
#     AND eventInfo.eventCategory = 'EnhancedEcommerce'
#     AND eventInfo.eventAction = 'Order Completed'
#     AND eventInfo.eventLabel = 'event'
#   GROUP BY
#     1,
#     2,
#     3,
#     4,
#     5 )

# SELECT
# 	first_exposure_date,
# 	exposure.user_id,
# 	exposure.variation,
# 	enrollments.course_id AS enrolled_course_id,
# 	transactions.transactionId,
# 	transactions.bookings_usd,
# 	transactions.course_id AS verified_course_id
# FROM
# 	exposure exposure
# JOIN
#     exposure_filtered exposure_filtered
# ON
#     exposure.user_id = exposure_filtered.user_id
# LEFT JOIN
# 	enrollments enrollments
# ON
# 	exposure.user_id = enrollments.user_id
# --AND
# 	--enrollments.date >= exposure.first_exposure_date 
# LEFT JOIN
# 	transactions transactions
# ON
# 	exposure.user_id = transactions.user_id
# AND
# 	transactions.date >= exposure.first_exposure_date
# AND
#   enrollments.course_id = transactions.course_id

# """.format(
# EXPERIMENT_CUSTOM_DIMENSION = EXPERIMENT_CUSTOM_DIMENSION,
# EXPERIMENT_START_DATE = EXPERIMENT_START_DATE,
# EXPERIMENT_END_DATE = EXPERIMENT_END_DATE,
# COURSE_ENROLLMENT_REGEXP = COURSE_ENROLLMENT_REGEXP,
# # COURSE_TRANSACTION_REGEXP = COURSE_TRANSACTION_REGEXP

# )