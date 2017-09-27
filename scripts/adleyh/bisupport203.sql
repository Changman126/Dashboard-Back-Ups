CREATE TABLE ahemphill.bisupport_203 (user_email varchar(555), user_group varchar(555));

COPY ahemphill.bisupport_203 FROM LOCAL '/Users/adleyhemphill/Documents/rit_cyber_test_holdout.csv' WITH DELIMITER ',';

SELECT
c.user_group,
current_enrollment_mode,
count(1),
count(distinct a.user_id)
from production.d_user_course a
join production.d_user b
on a.user_id = b.user_id
and a.course_id = 'course-v1:RITx+CYBER501x+1T2017'
join ahemphill.bisupport_203 c
on b.user_email = c.user_email
group by 1,2

CREATE TABLE ahemphill.bisupport_203_2 (user_email varchar(555), user_group varchar(555));

COPY ahemphill.bisupport_203_2 FROM LOCAL '/Users/adleyhemphill/Documents/rit_cyber_test_holdout_hpal.csv' WITH DELIMITER ',';

SELECT
c.user_group,
current_enrollment_mode,
count(1),
count(distinct a.user_id)
from production.d_user_course a
join production.d_user b
on a.user_id = b.user_id
and a.course_id = 'course-v1:RITx+CYBER501x+1T2017'
join ahemphill.bisupport_203_2 c
on b.user_email = c.user_email
group by 1,2