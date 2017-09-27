SELECT
	course_id,
	COUNT(1) AS cnt_enrolls,
	COUNT(first_verified_enrollment_time) AS cnt_verifs,
	SUM(is_certified)
FROM d_user_course a
LEFT JOIN d_user_course_certificate b
ON a.course_id = b.course_id
WHERE
	a.course_id IN
(
'course-v1:MichiganX+UX501x+3T2016',
'course-v1:MichiganX+SW101x+2T2016',
'course-v1:MichiganX+LeadEd501x+1T2017',
'course-v1:IIMBx+EP101x+1T2017',
'course-v1:ANUx+EBM01x+1T2017',
'course-v1:MITx+CTL.SC0x_2+1T2017',
'course-v1:MITx+CTL.SC0x+3T2016'
)
GROUP BY 1

select * from
(
SELECT
a.user_id,
a.course_id
FROM d_user_course a
JOIN d_user_course_certificate b
ON a.course_id = b.course_id
AND a.user_id = b.user_id
AND a.course_id IN
(
'course-v1:MITx+CTL.SC0x_2+1T2017',
'course-v1:MITx+CTL.SC0x+3T2016'
)
AND is_certified = 1
) a
join d_user_course_certificate b
ON a.user_id = b.user_id
AND b.course_id IN
(
'course-v1:MITx+CTL.SC1x_2+1T2016',
'course-v1:MITx+CTL.SC1x_3+1T2017',
'course-v1:MITx+CTL.SC1x_1+2T2015',
'MITx/ESD.SCM1x/3T2014'
)
AND is_certified = 1