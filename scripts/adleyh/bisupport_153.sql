drop table ahemphill.bisupport_153_1;
create table ahemphill.bisupport_153_1 as
SELECT
        distinct
        a.user_id,
        d.user_email,
        a.course_id,
        b.course_end_date,
        b.course_verification_end_date,
        datediff('day',current_date(), b.course_end_date)
       from production.d_user_course a
       join business_intelligence.course_master b
       on a.course_id = b.course_id
       and datediff('day',current_date(), b.course_end_date) between -30 and 0
       join production.f_user_activity c
       on a.user_id = c.user_id
       and a.course_id = c.course_id
       and datediff('day',current_date(), c.date) between -30 and 0
       join production.d_user d
       on a.user_id = d.user_id


drop table ahemphill.bisupport_153_2;
create table ahemphill.bisupport_153_2 as
SELECT
        distinct
        a.user_id,
        d.user_email,
        a.course_id,
        b.course_end_date,
        b.course_verification_end_date,
        datediff('day',current_date(), b.course_end_date)
       from production.d_user_course a
       join business_intelligence.course_master b
       on a.course_id = b.course_id
       and a.current_enrollment_mode = 'verified'
       and datediff('day',current_date(), b.course_end_date) between -14 and 0
       join production.d_user_course_certificate c
       on a.user_id = c.user_id
       and a.course_id = c.course_id
       and datediff('day',current_date(), c.modified_date) between -14 and 0
       and c.is_certified = 1
       join production.d_user d
       on a.user_id = d.user_id