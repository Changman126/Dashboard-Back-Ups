DROP TABLE IF EXISTS ahemphill.prof_ed_whitelabel_course_list;


CREATE TABLE IF NOT EXISTS ahemphill.prof_ed_whitelabel_course_list AS
SELECT a.course_id,
       CASE
           WHEN b.org_id NOT IN ( 'MITProfessionalX',
                                  'HarvardXPLUS',
                                  'HarvardMedGlobalAcademy',
                                  'JuilliardOpenClassroom' ) THEN 'white_label'
           ELSE 'prof_ed'
       END AS course_type
FROM
  ( SELECT DISTINCT course_id
   FROM production.d_user_course
   WHERE current_enrollment_mode IN ('professional',
                                     'no-id-professional') ) a
LEFT JOIN production.d_course b ON a.course_id = b.course_id;


DROP TABLE IF EXISTS ahemphill.course_subjects_deduped;


CREATE TABLE IF NOT EXISTS ahemphill.course_subjects_deduped AS
SELECT a.course_id,
       b.subject_title
FROM production.d_course a
JOIN
  ( SELECT course_id,
           subject_title,
           row_number() OVER (partition BY course_id
                              ORDER BY row_number ASC) AS rank
   FROM production.d_course_subjects) b ON a.course_id = b.course_id
WHERE b.rank = 1;


DROP TABLE IF EXISTS ahemphill.course_master;


CREATE TABLE IF NOT EXISTS ahemphill.course_master AS
SELECT a.course_id,
       a.catalog_course_title AS course_title,
       DATE(a.start_time) AS course_start_date,
       DATE(a.end_time) AS course_end_date,
       DATE(a.enrollment_start_time) AS course_enrollment_start_date,
       DATE(a.enrollment_end_time) AS course_enrollment_end_date,
       a.content_language AS course_content_language,
       a.pacing_type AS course_pacing_type,
       a.level_type AS course_level_type,
       a.availability AS course_availability,
       a.org_id AS org_id,
       a.partner_short_code AS partner_short_code,
       b.program_type,
       b.program_title,
       c.subject_title AS course_subject_title,
       d.course_seat_price,
       d.course_seat_currency,
       DATE(d.course_seat_upgrade_deadline) AS course_seat_upgrade_end_date,
       COALESCE(e.course_type, 'N/A') AS course_type
FROM d_course a
LEFT JOIN d_program_course b ON a.course_id = b.course_id
LEFT JOIN ahemphill.course_subjects_deduped c ON a.course_id = c.course_id
LEFT JOIN d_course_seat d ON a.course_id = d.course_id
AND d.course_seat_type = 'verified'
LEFT JOIN ahemphill.prof_ed_whitelabel_course_list e ON a.course_id = e.course_id