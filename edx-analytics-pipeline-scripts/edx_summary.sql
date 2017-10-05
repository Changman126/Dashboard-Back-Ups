DROP TABLE IF EXISTS edx_summary;
CREATE TABLE edx_summary AS
SELECT
  COUNT(1) AS 'total_enrollments',
  SUM(CASE WHEN first_verified_enrollment_time IS NOT NULL THEN 1 ELSE 0 END) AS 'total_verified_enrollments',
  SUM(CASE WHEN first_credit_enrollment_time IS NOT NULL THEN 1 ELSE 0 END) AS 'total_credit_enrollments'
FROM
  production.d_user_course;

GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO standard;
GRANT SELECT ON ALL TABLES IN SCHEMA business_intelligence TO analyst;