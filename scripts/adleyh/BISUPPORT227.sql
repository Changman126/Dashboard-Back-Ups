SELECT 
	a.course_id,
	b.current_enrollment_mode, 
	count(1), 
	count(distinct a.user_id) 
FROM
(
	SELECT 
		*,
		RANK() OVER (PARTITION BY user_id, course_id ORDER BY week DESC) AS rank
	FROM 
		ahemphill.user_activity_engagement_weekly
	WHERE 
		course_id IN
	(
		'course-v1:IDBx+IDB6x+1T2017',
		'course-v1:ColumbiaX+DS103x+1T2017',
		'course-v1:RITx+CYBER502x+2T2017',
		'course-v1:DelftX+PV1x+1T2017',
		'course-v1:USMx+CC605x+2T2017',
		'course-v1:USMx+STV1.1x+2T2017',
		'course-v1:HarvardX+PH525.1x+2T2016',
		'course-v1:GTx+ICT100x+1T2016',
		'course-v1:KULeuvenX+EWBCx+3T2016',
		'course-v1:Microsoft+DEV204x+1T2017',
		'course-v1:Microsoft+CLD213x+1T2017',
		'course-v1:Microsoft+DEV211.1x+2T2017',
		'course-v1:HarvardX+PH526x+3T2016',
		'course-v1:UQx+Crime101x+3T2016',
		'course-v1:BerkeleyX+GG101x+1T2017',
		'course-v1:UC3Mx+IT.1.1x+3T2016'
	)
) a
LEFT JOIN 
	production.d_user_course b
ON 
	a.user_id = b.user_id
AND 
	a.course_id = b.course_id
JOIN
	course_master c
ON
	a.course_id = c.course_id
AND
	c.course_start_date <= '2017-05-22'
WHERE 
	rank IN (1,2)
AND 
	weekly_engagement_level != 'no_engagement'
AND 
	week IN ('week_1','week_2', 'week_3', 'week_4')
AND 
	current_enrollment_mode = 'audit'
GROUP BY 
	a.course_id,
	b.current_enrollment_mode;

SELECT 
	DISTINCT a.user_id,
	a.course_id,
	d.user_email
FROM
(
	SELECT 
		*,
		RANK() OVER (PARTITION BY user_id, course_id ORDER BY week DESC) AS rank
	FROM 
		ahemphill.user_activity_engagement_weekly
	WHERE 
		course_id IN
	(
		'course-v1:IDBx+IDB6x+1T2017',
		'course-v1:ColumbiaX+DS103x+1T2017',
		'course-v1:RITx+CYBER502x+2T2017',
		'course-v1:DelftX+PV1x+1T2017',
		'course-v1:USMx+CC605x+2T2017',
		'course-v1:USMx+STV1.1x+2T2017',
		'course-v1:HarvardX+PH525.1x+2T2016',
		'course-v1:GTx+ICT100x+1T2016',
		'course-v1:KULeuvenX+EWBCx+3T2016',
		'course-v1:Microsoft+DEV204x+1T2017',
		'course-v1:Microsoft+CLD213x+1T2017',
		'course-v1:Microsoft+DEV211.1x+2T2017',
		'course-v1:HarvardX+PH526x+3T2016',
		'course-v1:UQx+Crime101x+3T2016',
		'course-v1:BerkeleyX+GG101x+1T2017',
		'course-v1:UC3Mx+IT.1.1x+3T2016'
	)
) a
LEFT JOIN 
	production.d_user_course b
ON 
	a.user_id = b.user_id
AND 
	a.course_id = b.course_id
JOIN
	course_master c
ON
	a.course_id = c.course_id
AND
	c.course_start_date <= '2017-05-22'
JOIN
	production.d_user d
ON
	a.user_id = d.user_id
WHERE 
	rank IN (1,2)
AND 
	weekly_engagement_level != 'no_engagement'
AND 
	week IN ('week_1','week_2', 'week_3', 'week_4')
AND 
	current_enrollment_mode = 'audit';

SELECT 
	DISTINCT a.user_id,
	a.course_id,
	d.user_email
FROM
(
	SELECT 
		*,
		RANK() OVER (PARTITION BY user_id, course_id ORDER BY week DESC) AS rank
	FROM 
		ahemphill.user_activity_engagement_weekly
	WHERE 
		course_id IN
	(
		'course-v1:UQx+Crime101x+3T2016',
		'course-v1:USMx+CC605x+2T2017',
		'course-v1:USMx+STV1.1x+2T2017'
	)
) a
LEFT JOIN 
	production.d_user_course b
ON 
	a.user_id = b.user_id
AND 
	a.course_id = b.course_id
JOIN
	course_master c
ON
	a.course_id = c.course_id
AND
	c.course_start_date <= '2017-06-09'
JOIN
	production.d_user d
ON
	a.user_id = d.user_id
WHERE 
	rank IN (1,2)
AND 
	weekly_engagement_level != 'no_engagement'
AND 
	week IN ('week_1','week_2', 'week_3', 'week_4')
AND 
	current_enrollment_mode = 'audit';

---

SELECT
	a.user_id,
	course_id,
	user_email
FROM
	production.d_user_course a
LEFT JOIN
	production.d_user b
ON
	a.user_id = b.user_id
WHERE
	course_id IN
(
'course-v1:IDBx+IDB6x+1T2017',
'course-v1:RITx+CYBER502x+2T2017',
'course-v1:DelftX+PV1x+1T2017',
'course-v1:HarvardX+PH525.1x+2T2016',
'course-v1:KULeuvenX+EWBCx+3T2016',
'course-v1:UC3Mx+IT.1.1x+3T2016'
)
AND
	current_enrollment_mode = 'audit'
AND
	a.user_id IN (
					SELECT
						user_id
					FROM
						production.f_user_activity
					WHERE
						course_id IN
(
'course-v1:IDBx+IDB6x+1T2017',
'course-v1:RITx+CYBER502x+2T2017',
'course-v1:DelftX+PV1x+1T2017',
'course-v1:HarvardX+PH525.1x+2T2016',
'course-v1:KULeuvenX+EWBCx+3T2016',
'course-v1:UC3Mx+IT.1.1x+3T2016'
)
					AND
						date >= CURRENT_DATE-14
					AND
						activity_type IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM', 'POSTED_FORUM')	
				);

