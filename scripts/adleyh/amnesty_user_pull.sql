DROP TABLE IF EXISTS ahemphill.amnesty_user_data;
CREATE TABLE ahemphill.amnesty_user_data AS

SELECT
c.name,
d.user_email,
d.user_last_location_country_code AS country,
d.user_gender AS gender,
d.user_year_of_birth AS birth_year, 
d.user_level_of_education AS edx_education_level,
d.user_id as edx_user_id,
e.is_certified AS certificate_issued,
c.bio AS edx_bio,
c.goals AS edx_goals,
d.user_account_creation_time AS edx_created,
a.course_id AS edx_course_id,
e.final_grade AS edx_grade,
f.value AS email_opt_in

FROM d_user_course a
JOIN d_course b
ON a.course_id = b.course_id
AND a.course_id like '%Rights2x%'
join lms_read_replica.auth_userprofile c
on a.user_id = c.user_id
join d_user d
on a.user_id = d.user_id
LEFT JOIN d_user_course_certificate e
ON a.course_id = e.course_id
AND a.user_id = e.user_id
LEFT JOIN lms_read_replica.user_api_userorgtag f
ON d.user_id = f.user_id
AND f.key = 'email-optin'
and f.org = 'AmnestyInternationalX'