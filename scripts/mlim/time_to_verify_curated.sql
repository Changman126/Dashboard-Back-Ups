
drop table if exists curated.user_course_role;
create table curated.user_course_role as /*+ direct */
with user_roles_pre as (
select duc.course_id
-- ,      sca.role
,      duc.user_id
,      du.user_email
,      du.user_username
,      du.user_year_of_birth
,      nullif(du.user_level_of_education,'') user_education
,      nullif(du.user_gender,'') user_gender
,      max(min(case when role='instructor' then 'instructor' else role end)) over (partition by duc.course_id,duc.user_id order by max(case when role='instructor' then 0 else 1 end)) user_role
from production.d_user_course duc
       join production.d_user du
              on duc.user_id=du.user_id
       join lms_read_replica.student_courseaccessrole sca
              on duc.course_id=sca.course_id
              and duc.user_id=sca.user_id
group by 1,2,3,4,5,6,7
order by 1,2
       )
select course_id
,      user_id
,      user_email
,      user_username
,      user_year_of_birth
,      user_education
,      user_gender
,      user_role
,      dense_rank() over (order by user_role) user_role_id
from user_roles_pre;
select analyze_statistics('curated.user_course_role')
;

drop table if exists curated.tableau_user_course_role;
create table curated.tableau_user_course_role as 
select 0 user_role_id, 'learner' user_role
union all
select user_role_id
,      user_role
from curated.user_course_role
group by 1,2
order by 1,2;
select analyze_statistics('curated.tableau_user_course_role')
;


drop table if exists curated.user_activity_monthly;
create table curated.user_activity_monthly (
       activity_month date,
       activity_date date,
       course_id_key int,
       user_id int,
       user_role_id int,
       previous_activity_date date,
       previous_course_activity_date date,
       activity_type_id int,
       number_of_activities int,
       number_of_activities_to_purchases_week int,
       -- course_start_date date,
       -- course_end_date date,
       course_end_filter_id int,
       -- first_enrollment_mode_id int,
       current_enrollment_mode_id int,
       current_enrollment_mode_id_actual int,
       user_start_date_distance int,
       activity_week int,
       purchase_week int,
       last_activity_lag_days int,
       last_course_activity_lag_days int,
       activity_occurence int,
       attempted_course_problem int,
       problem_attempts int,
       problem_attempts_two_weeks int,
       first_attempted_problem_week int,
       first_attempted_problem_week_1_2 int,
       problem_number int,
       user_id_passed int,
       user_id_certified int,
       sequence_enrollment int,
       sequence_purchase int
              );
create projection curated.user_activity_monthly /*+createtype(P)*/
(
       activity_month encoding rle,
       activity_date encoding rle,
       course_id_key encoding rle,
       user_id,
       user_role_id,
       previous_activity_date,
       previous_course_activity_date,
       activity_type_id,
       number_of_activities,
       number_of_activities_to_purchases_week,
       -- course_start_date encoding rle,
       -- course_end_date encoding rle,
       course_end_filter_id encoding rle,
       -- first_enrollment_mode_id,
       current_enrollment_mode_id,
       current_enrollment_mode_id_actual,
       user_start_date_distance,
       activity_week,
       purchase_week,
       last_activity_lag_days,
       last_course_activity_lag_days,
       activity_occurence,
       attempted_course_problem encoding rle,
       problem_attempts encoding rle,
       problem_attempts_two_weeks encoding rle,
       first_attempted_problem_week encoding rle,
       first_attempted_problem_week_1_2 encoding rle,
       problem_number,
       user_id_passed,
       user_id_certified,
       sequence_enrollment,
       sequence_purchase
)
as
 select user_activity_monthly.activity_month,
       user_activity_monthly.activity_date,
       user_activity_monthly.course_id_key,
       user_activity_monthly.user_id,
       user_activity_monthly.user_role_id,
       user_activity_monthly.previous_activity_date,
       user_activity_monthly.previous_course_activity_date,
       user_activity_monthly.activity_type_id,
       user_activity_monthly.number_of_activities,
       user_activity_monthly.number_of_activities_to_purchases_week,
       -- user_activity_monthly.course_start_date,
       -- user_activity_monthly.course_end_date,
       user_activity_monthly.course_end_filter_id,
       -- user_activity_monthly.first_enrollment_mode_id,
       user_activity_monthly.current_enrollment_mode_id,
       user_activity_monthly.current_enrollment_mode_id_actual,
       user_activity_monthly.user_start_date_distance,
       user_activity_monthly.activity_week,
       user_activity_monthly.purchase_week,
       user_activity_monthly.last_activity_lag_days,
       user_activity_monthly.last_course_activity_lag_days,
       user_activity_monthly.activity_occurence,
       user_activity_monthly.attempted_course_problem,
       user_activity_monthly.problem_attempts,
       user_activity_monthly.problem_attempts_two_weeks,
       user_activity_monthly.first_attempted_problem_week,
       user_activity_monthly.first_attempted_problem_week_1_2,
       user_activity_monthly.problem_number,
       user_activity_monthly.user_id_passed,
       user_activity_monthly.user_id_certified,
       user_activity_monthly.sequence_enrollment,
       user_activity_monthly.sequence_purchase
from curated.user_activity_monthly
order by user_activity_monthly.activity_month,
       user_activity_monthly.activity_date,
       user_activity_monthly.course_id_key,
       user_activity_monthly.user_id,
       user_activity_monthly.activity_occurence,
       user_activity_monthly.previous_activity_date
       segmented by hash(user_id) all nodes;


drop table if exists curated.user_monthly_enrollment;
CREATE TABLE curated.user_monthly_enrollment
(
    course_id varchar(255),
    user_id int,
    first_enrollment_time timestamp,
    first_enrollment_mode varchar(100),
    first_verified_enrollment_time timestamp,
    current_enrollment_mode_id int,
    enrollment_id int,
    user_role_id int,
    has_passed int,
    -- cert_test int,
    is_certified int,
    sequence_enrollment int,
    sequence_purchase int
);
CREATE PROJECTION curated.user_monthly_enrollment /*+createtype(P)*/ 
(
 course_id ENCODING RLE,
 user_id,
 first_enrollment_time,
 first_enrollment_mode,
 first_verified_enrollment_time,
 current_enrollment_mode_id,
 enrollment_id,
 user_role_id,
 has_passed,
 -- cert_test,
 is_certified,
 sequence_enrollment,
 sequence_purchase
)
AS
 SELECT user_monthly_enrollment.course_id,
        user_monthly_enrollment.user_id,
        user_monthly_enrollment.first_enrollment_time,
        user_monthly_enrollment.first_enrollment_mode,
        user_monthly_enrollment.first_verified_enrollment_time,
        user_monthly_enrollment.current_enrollment_mode_id,
        user_monthly_enrollment.enrollment_id,
        user_monthly_enrollment.user_role_id,
        user_monthly_enrollment.has_passed,
        -- user_monthly_enrollment.cert_test,
        user_monthly_enrollment.is_certified,
        user_monthly_enrollment.sequence_enrollment,
        user_monthly_enrollment.sequence_purchase
 FROM curated.user_monthly_enrollment
 ORDER BY user_monthly_enrollment.course_id,
          user_monthly_enrollment.user_id
SEGMENTED BY hash(user_monthly_enrollment.user_id) ALL NODES ;

drop table if exists curated.course_overviews_users;
create table curated.course_overviews_users as /*+ direct */
select coo.id course_id
,      gp.user_id
,      gp.percent_grade
,      gp.letter_grade
,      case when gp.percent_grade>=max(coo.lowest_passing_grade) then 1 end passing_grade
,      max(coo.lowest_passing_grade) lowest_passing_grade
,      max(coo.effort::varchar(100)) effort
,      avg(percent_grade) over course course_grade_avg
,      stddev_samp(percent_grade) over course course_grade_stddev
from lms_read_replica.course_overviews_courseoverview coo
       join lms_read_replica.grades_persistentcoursegrade gp
              on coo.id=gp.course_id
       --don't need courses that haven't started or have no user grades
group by 1,2,3,4
window course as (partition by coo.id)
order by 1,2
encoded by course_id encoding rle
segmented by hash(course_id) all nodes;
select analyze_statistics('curated.course_overviews_users')
;



truncate table curated.user_monthly_enrollment;
insert /*+ direct */ into curated.user_monthly_enrollment
select duc.course_id
,      duc.user_id
,      duc.first_enrollment_time
,      duc.first_enrollment_mode
,      duc.first_verified_enrollment_time
,      case 
              when duc.first_verified_enrollment_time is not null and duc.first_verified_enrollment_time::date-duc.first_enrollment_mode::date=0 then 3
              when duc.first_enrollment_mode='audit' and duc.first_verified_enrollment_time is not null then 7 
              when (duc.first_enrollment_mode not in ('audit','verified')) and duc.first_verified_enrollment_time is not null then 8
              when duc.first_verified_enrollment_time is not null then 3
              else erc.enrollment_id 
       end current_enrollment_mode_id
,      erc.enrollment_id
,      isnull(ucr.user_role_id,0) user_role_id
-- ,      cou.passing_grade
,      nullif(ducc.has_passed,0) has_passed
-- ,      case when passing_grade=1 and erc.enrollment_id in (3,7,8) then 1 end cert_test
,      nullif(ducc.is_certified,0) is_certified
,      dense_rank() over (partition by duc.user_id order by duc.first_enrollment_time) sequence_enrollment
,      case when duc.first_verified_enrollment_time is not null then dense_rank() over (partition by duc.user_id order by duc.first_verified_enrollment_time) end sequence_purchase
from production.d_user_course duc
       left join production.d_user_course_certificate ducc
              on duc.course_id=ducc.course_id
              and duc.user_id=ducc.user_id
       -- left join curated.course_overviews_users cou
       --        on duc.course_id=cou.course_id
       --        and duc.user_id=cou.user_id
       left join curated.tableau_user_enrollment_mode erc
              on duc.current_enrollment_mode=erc.current_enrollment_mode
       left join curated.user_course_role ucr
              on duc.course_id=ucr.course_id
              and duc.user_id=ucr.user_id
-- where not exists (select course_id,user_id from curated.user_course_role ucr where duc.course_id=ucr.course_id and duc.user_id=ucr.user_id)
              ;
select analyze_statistics('curated.user_monthly_enrollment')
;


truncate table curated.user_activity_monthly;
insert /*+ direct */ into curated.user_activity_monthly
select date_trunc('month',fua.date)::date activity_month
,      fua.date activity_date
,      hash(fua.course_id) course_id_key
,      fua.user_id 
,      duc.user_role_id
,      nullif(lag(fua.date) over course_date,fua.date) previous_activity_date
,      nullif(lag(fua.date) over course_user,fua.date) previous_course_activity_date
,      uat.activity_type_id
-- ,      case 
--               when max(case when activity_type_id=4 then 1 else 0 end) over course_problem
,      fua.number_of_activities
,      case when date_trunc('week',fua.date)<=date_trunc('week',first_verified_enrollment_time::date) then fua.number_of_activities end number_of_activities_to_purchases_week
-- ,      cm.course_start_date
-- ,      cm.course_end_date
,      case when cm.course_end_date is null then 1
              when cm.course_end_date<current_date then 3
              when cm.course_end_date>=current_date then 2
       end course_end_filter_id
-- ,      erf.enrollment_id first_enrollment_mode_id
-- ,      case 
--               when duc.first_verified_enrollment_time is not null and duc.first_verified_enrollment_time::date-duc.first_enrollment_mode::date=0 then 3
--               when duc.first_enrollment_mode='audit' and duc.first_verified_enrollment_time is not null then 7 
--               when (duc.first_enrollment_mode not in ('audit','verified')) and duc.first_verified_enrollment_time is not null then 8
--               when duc.first_verified_enrollment_time is not null then 3
--               else erc.enrollment_id 
--        end current_enrollment_mode_id
,      duc.current_enrollment_mode_id
,      duc.enrollment_id
,      duc.first_enrollment_time::date-cm.course_start_date course_start_date_distance
,      timestampdiff('week',duc.first_enrollment_time::date,fua.date)+1 activity_week
-- ,      min(case when date_trunc('week',fua.date)=date_trunc('week',first_verified_enrollment_time) then timestampdiff('week',duc.first_enrollment_time::date,fua.date)+1 end) over course_user purchase_week
,      timestampdiff('week',duc.first_enrollment_time::date,duc.first_verified_enrollment_time::date)+1
,      nullif(fua.date-lag(fua.date) over course_date,0) last_activity_lag_days
,      nullif(fua.date-lag(fua.date) over course_user,0) last_course_activity_lag_days
,      row_number() over (partition by fua.course_id,fua.date,fua.user_id order by row_number) activity_occurence
,      max(case when activity_type_id=4 then 1 else 0 end) over course_problem attempted_course_problem
,      sum(case when activity_type_id=4 then 1 else 0 end) over course_problem problem_attempts
,      sum(case when activity_type_id=4 and timestampdiff('week',duc.first_enrollment_time::date,fua.date)<=1 then 1 else 0 end) over course_problem problem_attempts_two_weeks
,      min(case when activity_type_id=4 then timestampdiff('week',duc.first_enrollment_time::date,fua.date)+1 end) over course_problem first_attempted_problem_week
,      max(case when activity_type_id=4 and timestampdiff('week',duc.first_enrollment_time::date,fua.date)<=1 then 1 else 0 end) over course_problem first_attempted_problem_week_1_2
,      case when activity_type_id=4 then row_number() over course_problem end problem_number
-- ,      case when ducc.has_passed=1 then ducc.user_id end user_id_passed
-- ,      case when ducc.is_certified=1 then ducc.user_id end user_id_certified
,      case when duc.has_passed = 1 then duc.user_id end user_id_passed
,      case when duc.is_certified = 1 then duc.user_id end user_id_certified
-- ,      dense_rank() over (partition by duc.user_id order by duc.first_enrollment_time) sequence_enrollment
-- ,      case when duc.first_verified_enrollment_time is not null then dense_rank() over (partition by duc.user_id order by duc.first_verified_enrollment_time) end sequence_purchase
,      duc.sequence_enrollment
,      duc.sequence_purchase
from production.f_user_activity fua
       -- join production.d_user_course duc
       --        on fua.course_id=duc.course_id
       --        and fua.user_id=duc.user_id
       join curated.user_monthly_enrollment duc
              on fua.course_id=duc.course_id
              and fua.user_id=duc.user_id
       join business_intelligence.course_master cm
              on fua.course_id=cm.course_id
              -- and cm.is_wl=0
       -- join curated.tableau_user_enrollment_mode erc
       --        on duc.current_enrollment_mode=erc.current_enrollment_mode
       join curated.tableau_user_activity_type uat
              on fua.activity_type=uat.activity_type
       -- left join production.d_user_course_certificate ducc
       --        on duc.course_id=ducc.course_id
       --        and duc.user_id=ducc.user_id
       -- join curated.tableau_user_enrollment_mode erf
       --        on duc.first_enrollment_mode=erf.current_enrollment_mode
window course_user as (partition by fua.user_id,fua.course_id order by fua.date,row_number)
,      course_date as (partition by fua.user_id order by fua.date)
,      course_problem as (partition by fua.user_id,fua.course_id order by case when activity_type_id=4 then 0 else 1 end,fua.date,row_number);
select analyze_statistics('curated.user_activity_monthly')
;