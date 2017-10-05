DROP TABLE IF EXISTS business_intelligence.user_content_availability_date;
CREATE TABLE IF NOT EXISTS business_intelligence.user_content_availability_date AS

SELECT
    user_course.user_id,
    user_course.course_id,
    user_course.current_enrollment_mode,
    CASE 
        WHEN DATE(user_course.first_enrollment_time) >= course.course_start_date THEN DATE(user_course.first_enrollment_time)
        ELSE course.course_start_date
    END AS content_availability_date,
    CASE 
        WHEN DATE(user_course.first_enrollment_time) < course.course_start_date THEN 'enroll_before_course_start'
        ELSE 'enroll_after_course_start'
    END AS enroll_group,
    user_course.first_enrollment_time,
    user_course.first_verified_enrollment_time,
    user_course.last_unenrollment_time
FROM 
    production.d_user_course user_course
JOIN 
    business_intelligence.course_master course
ON 
    user_course.course_id = course.course_id;
