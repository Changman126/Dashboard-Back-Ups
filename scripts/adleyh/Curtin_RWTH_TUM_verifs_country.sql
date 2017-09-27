select
country_name,
b.course_partner,
COUNT(1) AS cnt_verifications
from production.d_user_course a
join course_master b 
on a.course_id = b.course_id
AND a.current_enrollment_mode = 'verified'
and b.course_partner IN ('CurtinX', 'RWTHx', 'TUMx')
join production.d_user c
on a.user_id = c.user_id
join production.d_country d
on c.user_last_location_country_code = d.user_last_location_country_code
group by 1,2