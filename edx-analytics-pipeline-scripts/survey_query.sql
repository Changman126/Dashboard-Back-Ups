/* ========================================================================================
* Initialize survey_history table with most recently surveyed contacts
* Indentify contacts who should be surveyed for courses ending (this month - 1). 
  We run this query at the start of the month, e.g. Sept 1), and add rows for eligible 
  users not surveyed last month
======================================================================================== */

CREATE TABLE IF NOT EXISTS business_intelligence.survey_history (
        user_id VARCHAR(255),
        user_email VARCHAR(255),
        course_id VARCHAR(255),
        month_surveyed INT -- month in which course ended and the user was eligible to be surveyed
);

-- initialize survey_history table
INSERT INTO 
    business_intelligence.survey_history 
(
    SELECT
        users.user_id,
        users.user_email,
        courses.course_id,
        MONTH(NOW()) - 1 AS month_surveyed -- initialize w/ last month's contacts
    FROM
        lms_read_replica.student_courseaccessrole student_roles
    INNER JOIN
        production.d_user users
    ON
        student_roles.user_id = users.user_id
        AND user_email NOT LIKE '%edx.org%' -- exclude staff
        AND ( -- exclude beta testers
            role = 'instructor' 
            OR role = 'staff'
        ) 
    INNER JOIN
        production.d_course courses
    ON
        courses.course_id = student_roles.course_id
        AND YEAR(courses.end_time) = YEAR(NOW()) 
        AND MONTH(courses.end_time) = MONTH(NOW()) - 1  -- push in users for courses ending one month ago
    WHERE
        NOT EXISTS ( 
            SELECT
                *
            FROM
                business_intelligence.survey_history
        ) -- only insert when table is unitialized
);

-- insert this month's contacts-to-survey on the first of the month
INSERT INTO 
    business_intelligence.survey_history 
(
    SELECT
        users.user_id,
        users.user_email,
        courses.course_id,
        MONTH(NOW()) AS month_surveyed
    FROM
        lms_read_replica.student_courseaccessrole student_roles
    INNER JOIN
        production.d_user users
    ON
        student_roles.user_id = users.user_id
        AND user_email NOT LIKE '%edx.org%' -- exclude staff
        AND ( -- exclude beta testers
            role = 'instructor' 
            OR role = 'staff'
        ) 
    INNER JOIN
        production.d_course courses
    ON 
        courses.course_id = student_roles.course_id
        AND YEAR(courses.end_time) = YEAR(NOW()) 
        AND MONTH(courses.end_time) = MONTH(NOW())  -- we run this script 1 week before course end for courses ending this month
    WHERE 
        day(NOW()) = 24 -- only run on 24th of the month
);