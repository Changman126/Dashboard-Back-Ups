DROP TABLE ahemphill.bisupport99;

CREATE TABLE ahemphill.bisupport99 (email VARCHAR(64), first_email VARCHAR(64), second_email VARCHAR(64) );

COPY ahemphill.bisupport99 FROM LOCAL '/Users/adleyhemphill/Downloads/bisupport_99.csv' DELIMITER ','

select count(1), count(distinct email) from ahemphill.bisupport99

select
a.user_id,
c.email,
c.first_email,
c.second_email,
a.first_verified_enrollment_time,
a.current_enrollment_mode,
SUM(CASE WHEN d.date <= '2017-02-15' THEN 1 ELSE 0 END) AS cnt_active_before_first_email,
SUM(CASE WHEN d.date <= '2017-02-16' THEN 1 ELSE 0 END) AS cnt_active_before_second_email,
SUM(CASE WHEN d.date <= '2017-02-15' AND activity_type != 'ACTIVE' THEN 1 ELSE 0 END) AS cnt_engaged_before_first_email,
SUM(CASE WHEN d.date <= '2017-02-16' AND activity_type != 'ACTIVE' THEN 1 ELSE 0 END) AS cnt_engaged_before_second_email
from d_user_course a 
join d_user b
on a.user_id = b.user_id
and a.course_id = 'course-v1:RITx+PM9001x+1T2017'
join ahemphill.bisupport99 c
on b.user_email = c.email
left join f_user_activity d
on a.user_id = d.user_id
and a.course_id = d.course_id
group by 1,2,3,4,5,6