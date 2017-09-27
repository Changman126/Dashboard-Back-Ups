DROP TABLE IF EXISTS ahemphill.problem_attempted_video_watched_activity;
CREATE TABLE IF NOT EXISTS ahemphill.problem_attempted_video_watched_activity AS

SELECT
	a.course_id,
	COUNT(DISTINCT a.user_id) AS cnt_users
FROM
	f_user_activity a
WHERE
	activity_type  IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM') 
GROUP BY 1;

DROP TABLE IF EXISTS ahemphill.problem_attempted_video_watched_activity_w_enrolls;
CREATE TABLE IF NOT EXISTS ahemphill.problem_attempted_video_watched_activity_w_enrolls AS

SELECT
	a.course_id,
	c.pacing_type,
	a.cnt_users AS cnt_active_users,
	b.cnt_enrolled_users,
	datediff('day', c.enrollment_start_time, c.start_time) AS announce_date_days_prior_course_start,
	a.cnt_users*100.0/cnt_enrolled_users AS pct_active_users

FROM
	ahemphill.problem_attempted_video_watched_activity a
JOIN
	(
		SELECT
			course_id,
			COUNT(1) AS cnt_enrolled_users
		FROM
			d_user_course
		GROUP BY 1
	) b
ON a.course_id = b.course_id
JOIN d_course c
ON a.course_id = c.course_id
;


DROP TABLE IF EXISTS ahemphill.self_paced_instructor_led_same_courses_2016_activity;
CREATE TABLE IF NOT EXISTS ahemphill.self_paced_instructor_led_same_courses_2016_activity AS

SELECT
	b.user_id,
	a.course_id,
	c.pacing_type,
	SUM(CASE WHEN activity_type NOT IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM') OR activity_type IS NULL THEN 0 ELSE number_of_activities END) AS cnt_activities
	--SUM(CASE WHEN activity_type IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM') THEN number_of_activities ELSE 0 END) AS cnt_activities
FROM
	d_user_course b
LEFT JOIN f_user_activity a 
ON a.user_id = b.user_id
AND a.course_id = b.course_id 
JOIN d_course c
ON a.course_id = c.course_id
AND c.availability IN ('Archived', 'Current')
AND c.course_id IN
(
'course-v1:AdelaideX+Project101x+1T2016',
'course-v1:AdelaideX+Project101x+2T2016',
'course-v1:ANUx+ANU-ASTRO3x+1T2016',
'course-v1:ANUx+ANU-ASTRO3x+4T2015',
'course-v1:ANUx+ANU-ASTRO4x+2T2016',
'course-v1:ANUx+ANU-ASTRO4x+4T2015',
'course-v1:BerkeleyX+GG101x+1T2016',
'course-v1:BerkeleyX+GG101x+3T2016',
'course-v1:Catalystx+IL5x+2016_T1',
'course-v1:Catalystx+IL5x+2T2016',
'course-v1:CatalystX+ILX2+2016_1T',
'course-v1:CatalystX+ILX2+2016_T2',
'course-v1:CatalystX+ILX2+3T2016',
'course-v1:ColumbiaX+DS102X+1T2016',
'course-v1:ColumbiaX+DS102X+2T2016',
'course-v1:ColumbiaX+DS103x+1T2016',
'course-v1:ColumbiaX+DS103x+2T2016',
'course-v1:DelftX+LfE101x+1T2016',
'course-v1:DelftX+LfE101x+3T2016',
'course-v1:ETHx+FC-02x+2T2016',
'course-v1:ETHx+FC-02x+T1_2016',
'course-v1:Harvardx+HLS2X+2T2016',
'course-v1:Harvardx+HLS2X+3T2016',
'course-v1:Harvardx+HLS2X+T12016',
'course-v1:HKPolyUx+EWA1.1x+2T2016',
'course-v1:HKPolyUx+EWA1.1x+3T2016',
'course-v1:HKUSTx+COMP102.1x+2T2016',
'course-v1:HKUSTx+COMP102.1x+3T2016',
'course-v1:HKUSTx+COMP107x+1T2016',
'course-v1:HKUSTx+COMP107x+3T2016',
'course-v1:IEEEx+SmartGrid.x+2016_T2',
'course-v1:IEEEx+SmartGrid01.x+3T2016',
'course-v1:IIMBx+IM110x+1T2016',
'course-v1:IIMBx+IM110x+3T2016',
'course-v1:IITBombayX+CS101.1x+1T2016',
'course-v1:IITBombayX+CS101.1x+2T2016',
'course-v1:KyotoUx+004x+1T2016',
'course-v1:KyotoUx+004x+2T2016',
'course-v1:LouvainX+Louv9x+1T2016',
'course-v1:LouvainX+Louv9x+2T2016',
'course-v1:Microsoft+DAT205x+2T2016',
'course-v1:Microsoft+DAT205x+3T2016',
'course-v1:Microsoft+DAT208x+1T2016',
'course-v1:Microsoft+DAT208x+2T2016',
'course-v1:Microsoft+DAT208x+4T2016',
'course-v1:Microsoft+DAT208x+5T2016',
'course-v1:Microsoft+DAT208x+6T2016',
'course-v1:Microsoft+DAT209x+1T2016',
'course-v1:Microsoft+DAT209x+4T2016',
'course-v1:Microsoft+DAT209x+5T2016',
'course-v1:W3Cx+HTML5.0x+1T2016',
'course-v1:W3Cx+HTML5.0x+2T_2016',
'course-v1:W3Cx+HTML5.1x+2T2016',
'course-v1:W3Cx+HTML5.1x+3T2016',
'course-v1:W3Cx+HTML5.2x+1T2016',
'course-v1:W3Cx+HTML5.2x+2T2016'
)
GROUP BY
	1,2,3;

DROP TABLE IF EXISTS ahemphill.self_paced_instructor_led_same_courses_2016_activity_summary;
CREATE TABLE IF NOT EXISTS ahemphill.self_paced_instructor_led_same_courses_2016_activity_summary AS

SELECT
	course_id,
	pacing_type,
	sum(case when cnt_activities > 0 then 1 else 0 end)*100.0/count(1) AS activity_pct,
	count(1) as num_enrolls
FROM 
	ahemphill.self_paced_instructor_led_same_courses_2016_activity
GROUP BY 1,2;

DROP TABLE IF EXISTS ahemphill.self_paced_instructor_led_same_courses_activity;
CREATE TABLE IF NOT EXISTS ahemphill.self_paced_instructor_led_same_courses_activity AS

SELECT
	b.user_id,
	a.course_id,
	c.pacing_type,
	SUM(CASE WHEN activity_type NOT IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM') OR activity_type IS NULL THEN 0 ELSE number_of_activities END) AS cnt_activities
FROM
	d_user_course b
LEFT JOIN f_user_activity a 
ON a.user_id = b.user_id
AND a.course_id = b.course_id 
JOIN d_course c
ON a.course_id = c.course_id
AND c.availability IN ('Archived', 'Current')
AND c.course_id IN
(
'AdelaideX/HumBio101x/1T2015',
'ANUx/ANU-ASTRO1x/1T2014',
'BerkeleyX/EE40LX/1T2015',
'BerkeleyX/GG101x/1T2014',
'BerkeleyX/J4SC101/1T2015',
'CaltechX/BEM1105x/1T2015',
'CatalystX/ILX1/2015_T1',
'CornellX/HIST1514x_Fall2014/3T2014',
'CornellX/HIST1514x/1T2014',
'CornellX/INFO2040x_Spring2015/1T2015',
'CornellX/INFO2040x/1T2014',
'course-v1:AdelaideX+Cyber101x+1T2016',
'course-v1:AdelaideX+Cyber101x+2T2015',
'course-v1:AdelaideX+HumBio101x+1T2016',
'course-v1:AdelaideX+HumBio101x+2T2015',
'course-v1:AdelaideX+Project101x+1T2016',
'course-v1:AdelaideX+Project101x+2T2016',
'course-v1:AdelaideX+Wine101x+1T2016',
'course-v1:AdelaideX+Wine101x+2T2015',
'course-v1:AdelaideX+Wine101x+2T2015.2',
'course-v1:ANUx+ANU-ActuarialX+1T2016',
'course-v1:ANUx+ANU-ActuarialX+3T2015',
'course-v1:ANUx+ANU-ActuarialX+4T2015',
'course-v1:ANUx+ANU-ASTRO1x+2T2015',
'course-v1:ANUx+ANU-ASTRO1x+2T2016',
'course-v1:ANUx+ANU-ASTRO1x+3T2015',
'course-v1:ANUx+ANU-ASTRO2x+2T2016',
'course-v1:ANUx+ANU-ASTRO2x+3T2015',
'course-v1:ANUx+ANU-ASTRO2x+4T2015',
'course-v1:ANUx+ANU-ASTRO3x+1T2016',
'course-v1:ANUx+ANU-ASTRO3x+4T2015',
'course-v1:ANUx+ANU-ASTRO4x+2T2016',
'course-v1:ANUx+ANU-ASTRO4x+4T2015',
'course-v1:BerkeleyX+EE40LX+2T2015',
'course-v1:BerkeleyX+GG101x-2+1T2015',
'course-v1:BerkeleyX+GG101x+1T2016',
'course-v1:BerkeleyX+GG101x+3T2015',
'course-v1:BerkeleyX+GG101x+3T2016',
'course-v1:BerkeleyX+J4SC101x+1T2016',
'course-v1:CaltechX+BEM1105x+1T2016',
'course-v1:CaltechX+BEM1105x+3T2015',
'course-v1:Catalystx+IL5x+2016_T1',
'course-v1:Catalystx+IL5x+2T2016',
'course-v1:CatalystX+ILX2+2015_2T',
'course-v1:CatalystX+ILX2+2016_1T',
'course-v1:CatalystX+ILX2+2016_T2',
'course-v1:CatalystX+ILX2+3T2016',
'course-v1:ColumbiaX+DS101X+1T2016',
'course-v1:ColumbiaX+DS101X+3T2015',
'course-v1:ColumbiaX+DS102X+1T2016',
'course-v1:ColumbiaX+DS102X+2T2016',
'course-v1:ColumbiaX+DS103x+1T2016',
'course-v1:ColumbiaX+DS103x+2T2016',
'course-v1:CornellX+HIST1514x+1T2015',
'course-v1:CornellX+INFO2040x+1T2016',
'course-v1:DelftX+AE1110x+2T2015',
'course-v1:DelftX+AE1110x+3T2016',
'course-v1:DelftX+Calc001x+2T2016',
'course-v1:DelftX+CalcSP01x+3T2015',
'course-v1:Delftx+CircularX+1T2016',
'course-v1:Delftx+CircularX+3T2015',
'course-v1:DelftX+DDA691x+3T2015',
'course-v1:DelftX+DDA691x+3T2016',
'course-v1:DelftX+ET3034x+2T2016',
'course-v1:DelftX+ET3034x+3T2015',
'course-v1:DelftX+EX101x+1T2016',
'course-v1:DelftX+EX101x+3T2015',
'course-v1:DelftX+EX101x+3T2016',
'course-v1:DelftX+EX102+1T2016',
'course-v1:DelftX+EX102+2T2016',
'course-v1:DelftX+LfE101x+1T2016',
'course-v1:DelftX+LfE101x+3T2016',
'course-v1:DelftX+NGIx+3T2015',
'course-v1:DelftX+NGIx+3T2016',
'course-v1:DelftX+TPM1x+2T2015',
'course-v1:DelftX+TPM1x+2T2016',
'course-v1:DelftX+TW3421x+1T2016',
'course-v1:EPFLx+BrainX+3T2015',
'course-v1:EPFLx+BrainX+T1_2016',
'course-v1:ETHx+AMRx+1T2015',
'course-v1:ETHx+AMRx+2T2016',
'course-v1:ETHx+FC-01x+2016_T2',
'course-v1:ETHx+FC-01x+2T2015',
'course-v1:ETHx+FC-02x+2T2015',
'course-v1:ETHx+FC-02x+2T2016',
'course-v1:ETHx+FC-02x+T1_2016',
'course-v1:HarvardX+CS50+X',
'course-v1:Harvardx+HLS2X+2T2016',
'course-v1:Harvardx+HLS2X+3T2016',
'course-v1:Harvardx+HLS2X+T12016',
'course-v1:HarvardX+MCB80.1x+2T2016',
'course-v1:HarvardX+SPU30x+2T2016',
'course-v1:HarvardX+SPU30x+3T2016',
'course-v1:HarveyMuddX+CS002x+2T2015',
'course-v1:HarveyMuddX+CS002x+2T2016',
'course-v1:HKPolyUx+ANA101x+2T2015',
'course-v1:HKPolyUx+ANA101x+2T2016',
'course-v1:HKPolyUx+EWA.1x+3T2015',
'course-v1:HKPolyUx+EWA1.1x+2T2016',
'course-v1:HKPolyUx+EWA1.1x+3T2016',
'course-v1:HKUSTx+COMP102.1x+2T2015',
'course-v1:HKUSTx+COMP102.1x+2T2016',
'course-v1:HKUSTx+COMP102.1x+3T2016',
'course-v1:HKUSTx+COMP102.1x+4T2015',
'course-v1:HKUSTx+COMP107x+1T2016',
'course-v1:HKUSTx+COMP107x+2016_T1',
'course-v1:HKUSTx+COMP107x+3T2016',
'course-v1:IEEEx+CloudIntro.x+2015_T4',
'course-v1:IEEEx+CloudIntro.x+2015T2',
'course-v1:IEEEx+CloudIntro.x+2T2016',
'course-v1:IEEEx+RTSIx+1T2016',
'course-v1:IEEEx+RTSIx+2015_T3',
'course-v1:IEEEx+SmartGrid.x+2016_T2',
'course-v1:IEEEx+SmartGrid01.x+3T2016',
'course-v1:IIMBx+IM110x+1T2016',
'course-v1:IIMBx+IM110x+3T2016',
'course-v1:IITBombayX+CS101.1x+1T2016',
'course-v1:IITBombayX+CS101.1x+2T2016',
'course-v1:IITBombayX+CS101.1x+4T2015',
'course-v1:IITBombayX+EE210.1X+1T2016',
'course-v1:IITBombayX+EE210.1x+2T2016',
'course-v1:IITBombayX+ME209.1x+1T2016',
'course-v1:KIx+KIBEHMEDx+T1_2016',
'course-v1:KIx+KIeHealthX+T4_2015',
'course-v1:KIx+KIexploRx+2015T3',
'course-v1:KyotoUx+004x+1T2016',
'course-v1:KyotoUx+004x+2T2016',
'course-v1:LouvainX+Louv2x+1T2016',
'course-v1:LouvainX+Louv2x+2T2016',
'course-v1:LouvainX+Louv5x+3T2015',
'course-v1:LouvainX+Louv5x+3T2016',
'course-v1:LouvainX+Louv9x+1T2016',
'course-v1:LouvainX+Louv9x+2T2016',
'course-v1:Microsoft+CLOUD200x+3T2016',
'course-v1:Microsoft+DAT201x+1T2016',
'course-v1:Microsoft+DAT201x+2015_T2',
'course-v1:Microsoft+DAT201x+2015_T4',
'course-v1:Microsoft+DAT201x+5T2016',
'course-v1:Microsoft+DAT201x+6T2016',
'course-v1:Microsoft+DAT203x+1T2016',
'course-v1:Microsoft+DAT203x+3T2015',
'course-v1:Microsoft+DAT204x+1T2016',
'course-v1:Microsoft+DAT204x+3T2015',
'course-v1:Microsoft+DAT205x+2T2016',
'course-v1:Microsoft+DAT205x+3T2016',
'course-v1:Microsoft+DAT207x+1T2016',
'course-v1:Microsoft+DAT207x+3T2015',
'course-v1:Microsoft+DAT207x+4T2016',
'course-v1:Microsoft+DAT207x+5T2016',
'course-v1:Microsoft+DAT207x+6T2016',
'course-v1:Microsoft+DAT208x+1T2016',
'course-v1:Microsoft+DAT208x+2T2016',
'course-v1:Microsoft+DAT208x+4T2016',
'course-v1:Microsoft+DAT208x+5T2016',
'course-v1:Microsoft+DAT208x+6T2016',
'course-v1:Microsoft+DAT209x+1T2016',
'course-v1:Microsoft+DAT209x+4T2016',
'course-v1:Microsoft+DAT209x+5T2016',
'course-v1:Microsoft+DEV201x+1T2016',
'course-v1:Microsoft+DEV201x+2015_T2',
'course-v1:Microsoft+DEV201x+2015_T4',
'course-v1:Microsoft+DEV204x+1T2016',
'course-v1:Microsoft+DEV204x+2015_T2',
'course-v1:Microsoft+DEV204x+2015_T4',
'course-v1:Microsoft+DEV204x+2T2016',
'course-v1:Microsoft+DEV208x+1T2016',
'course-v1:Microsoft+DEV208x+2T2016',
'course-v1:Microsoft+DEV208x+3T2015',
'course-v1:Microsoft+DEV210x+1T2016',
'course-v1:Microsoft+DEV210x+2T2016',
'course-v1:Microsoft+DEV210x+3T2015',
'course-v1:Microsoft+INF201.12x+1T2016',
'course-v1:Microsoft+INF201.12x+3T2015',
'course-v1:Microsoft+INF201.13x+1T2016',
'course-v1:Microsoft+INF201.13x+3T2015',
'course-v1:MITx+15.390.2x_1+2T2015',
'course-v1:MITx+Launch.x_2+2T2016',
'course-v1:MITx+Launch.x_3+1T2017',
'course-v1:MITx+Launch.x+1T2016',
'course-v1:PurdueX+PN-15.2+2015_3T',
'course-v1:SMES+PSYCH101x+2T2015',
'course-v1:TBRx+EngCompX+2T2016',
'course-v1:TenarisUniversityX+STEEL101x_1+3T2015',
'course-v1:TenarisUniversityX+STEEL101x+2T2015',
'course-v1:TsinghuaX+30640014x+1T2016',
'course-v1:TsinghuaX+30640014x+2T2015',
'course-v1:TsinghuaX+30640014x+3T2015',
'course-v1:UBCx+SPD1x+1T2016',
'course-v1:UBCx+SPD1x+2T2015',
'course-v1:UBCx+UseGen.1x+1T2016',
'course-v1:UBCx+UseGen.1x+3T2015',
'course-v1:UCSDx+CSE167x+2T2016',
'course-v1:UCSDx+CSE167x+3T2015',
'course-v1:UCSDx+CSE167x+4T2015',
'course-v1:UPValenciaX+AIP201x+2T2016',
'course-v1:UPValenciaX+BI101x+2T2016',
'course-v1:UPValenciaX+BMD101x+2016_T2',
'course-v1:UPValenciax+IGP101.x+2T2016',
'course-v1:UPValenciax+IGP101.x+T32015',
'course-v1:UPValenciaX+xls101x+1T2016',
'course-v1:UQx+BIOIMG101x+1T2015',
'course-v1:UQx+BIOIMG101x+1T2016',
'course-v1:UQx+BIOIMG101x+2T2015',
'course-v1:UQx+Crime101x+1T2016',
'course-v1:UQx+Crime101x+2T2015',
'course-v1:UQx+Crime101x+3T2016',
'course-v1:UQx+Denial101x+2T2015',
'course-v1:UQx+HYPERS301.x+1T2015',
'course-v1:UQx+IELTSx+3T2015',
'course-v1:UQx+IELTSx+3T2016',
'course-v1:UQx+META101x+1T2016',
'course-v1:UQx+META101x+3T2015',
'course-v1:UQx+Think101x+1T2016',
'course-v1:UQx+Think101x+2T2015',
'course-v1:UQx+Think101x+3T2016',
'course-v1:UQx+Tropic101+2T2015',
'course-v1:UQx+Tropic101+2T2016',
'course-v1:UQx+World101x+2T2015',
'course-v1:UTAustinX+UT.PreC.10.02x+1T2016',
'course-v1:VJx+VJx_S+3T2015',
'course-v1:W3Cx+HTML5.0x+1T2016',
'course-v1:W3Cx+HTML5.0x+2T_2016',
'course-v1:W3Cx+HTML5.1x+2T2016',
'course-v1:W3Cx+HTML5.1x+3T2016',
'course-v1:W3Cx+HTML5.1x+4T2015',
'course-v1:W3Cx+HTML5.2x+1T2016',
'course-v1:W3Cx+HTML5.2x+2T2016',
'course-v1:W3Cx+HTML5.2x+4T2015',
'course-v1:WageningenX+NUTR102x+1T2016',
'course-v1:WageningenX+NUTR102x+3T2015',
'course-v1:WestonHS+PFLC1x+2T2016',
'DelftX/AE.1110x/3T2014',
'DelftX/AE1110x/1T2014',
'DelftX/Calc001x/2T2015',
'DelftX/ET.3034TU/3T2014',
'DelftX/ET3034TUx/2013_Fall',
'DelftX/TW.3421x/1T2015',
'DelftX/TW3421x/1T2014',
'EPFLx/BrainX/1T2015',
'ETHx/AMRx/1T2014',
'ETHx/FC-01x/3T2014',
'HarvardX/CS50x/2012',
'HarvardX/CS50x/2014_T1',
'HarvardX/CS50x3/2015',
'HarvardX/MCB80.1x/2013_SOND',
'HarvardX/SPU30x/2T2014',
'HarveyMuddX/CS002x/1T2015',
'IITBombayX/CS101.1x/2T2014',
'IITBombayX/EE210.1X/3T2015',
'IITBombayX/ME209.1x/2T2015',
'IITBombayX/ME209x/2T2014',
'KIx/KIBEHMEDx/3T2014',
'KIx/KIeHealthX/2T2015',
'KIx/KIexploRx/3T2014',
'LouvainX/Louv2.01x/1T2014',
'LouvainX/Louv2x/1T2015',
'LouvainX/Louv5x/2T2015',
'LouvainX/Louv9x/1T2015',
'MITx/15.390.2x/3T2014',
'PurdueX/pncom201501x/2015_T1',
'SMES/PSYCH101x/1T2015',
'TBRx/EngCompX/1T2015',
'TsinghuaX/30700313x/1T2015',
'UPValenciaX/AIP201x/2T2015',
'UPValenciaX/BI101x/2T2015',
'UPValenciaX/BMD101x/2T2015',
'UPValenciaX/EX101x/2T2015',
'UQx/BIOIMG101x/1T2014',
'UQx/Crime101x/3T2014',
'UQx/Denial101x/1T2015',
'UQx/HYPERS301x/1T2014',
'UQx/Think101x/1T2014',
'UQx/TROPIC101x/1T2014',
'UQx/World101x/3T2014',
'UTAustinX/UT.PreC.10.01x/3T2015',
'VJx/VJx/3T2014',
'WestonHS/PFLC1x/3T2015'
)
GROUP BY
	1,2,3;

DROP TABLE IF EXISTS ahemphill.self_paced_instructor_led_same_courses_activity_summary;
CREATE TABLE IF NOT EXISTS ahemphill.self_paced_instructor_led_same_courses_activity_summary AS

SELECT
	course_id,
	pacing_type,
	sum(case when cnt_activities > 0 then 1 else 0 end)*100.0/count(1) AS activity_pct,
	count(1) as num_enrolls
FROM 
	ahemphill.self_paced_instructor_led_same_courses_activity
GROUP BY 1,2;


SELECT
	a.user_id,
	a.course_id,
	b.pacing_type,
	MAX(a.first_enrollment_time, b.start_time) AS content_availability_date
FROM
	d_user_course a
JOIN
	d_course b 
ON a.course_id = b.course_id

---

--identify the first date that a user could have consumed content
--restrict to 2016 onward since f_user_activity is only logged since then
DROP TABLE IF EXISTS ahemphill.content_availability_date;
CREATE TABLE IF NOT EXISTS ahemphill.content_availability_date AS

SELECT
	a.user_id,
	a.course_id,
	b.pacing_type,
	CASE 
	WHEN a.first_enrollment_time >= b.start_time THEN a.first_enrollment_time
	ELSE b.start_time
	END AS content_availability_date
FROM
	d_user_course a
JOIN
	d_course b
ON a.course_id = b.course_id
WHERE CASE 
	WHEN a.first_enrollment_time >= b.start_time THEN a.first_enrollment_time
	ELSE b.start_time
	END >= '2016-01-01';

--aggregate ALL activity in a course for every user and course
DROP TABLE IF EXISTS ahemphill.problem_attempted_video_watched_activity_non_agg;
CREATE TABLE IF NOT EXISTS ahemphill.problem_attempted_video_watched_activity_non_agg AS
SELECT
    user_id,
    course_id,
    date,
    COUNT(1) AS cnt_activity
FROM f_user_activity
WHERE
	activity_type  IN ('PLAYED_VIDEO', 'ATTEMPTED_PROBLEM') 
GROUP BY
	1,2,3;

--combine activity data with date of first consumption. calculate how much content was consumed 
--across different windows
DROP TABLE IF EXISTS ahemphill.first_7d_activity_self_paced_instructor_led_summary;
CREATE TABLE IF NOT EXISTS ahemphill.first_7d_activity_self_paced_instructor_led_summary AS

SELECT
    a.user_id,
    a.course_id,
    a.pacing_type,
    SUM(CASE WHEN DATEDIFF('day',a.content_availability_date, b.date) BETWEEN 0 AND 7 THEN 1 ELSE 0 END ) AS num_days_active_7d,
    SUM(CASE WHEN DATEDIFF('day',a.content_availability_date, b.date) BETWEEN 0 AND 14 THEN 1 ELSE 0 END ) AS num_days_active_14d,
    SUM(CASE WHEN DATEDIFF('day',a.content_availability_date, b.date) BETWEEN 0 AND 21 THEN 1 ELSE 0 END ) AS num_days_active_21d
FROM
        ahemphill.content_availability_date a
LEFT JOIN
    ahemphill.problem_attempted_video_watched_activity_non_agg b
ON a.course_id = b.course_id
AND a.user_id = b.user_id
GROUP BY 1,2,3;

DROP TABLE IF EXISTS ahemphill.first_7d_activity_self_paced_instructor_led_summary2;
CREATE TABLE IF NOT EXISTS ahemphill.first_7d_activity_self_paced_instructor_led_summary2 AS
SELECT
	course_id,
	pacing_type,
	count(1) as num_enrolls,
	SUM(CASE WHEN num_days_active_7d > 0 THEN 1 ELSE 0 END) AS num_7d_active,
	SUM(CASE WHEN num_days_active_7d > 0 AND num_days_active_14d > num_days_active_7d THEN 1 ELSE 0 END) AS num_14d_active,
	SUM(CASE WHEN num_days_active_7d > 0 AND num_days_active_21d > num_days_active_7d THEN 1 ELSE 0 END) AS num_21d_active,
	SUM(CASE WHEN num_days_active_7d > 0 THEN 1 ELSE 0 END)*100.0/count(1) as pct_7d_active,
	SUM(CASE WHEN num_days_active_7d > 0 AND num_days_active_14d > num_days_active_7d THEN 1 ELSE 0 END)*100.0/count(1) as pct_14d_active,	
	SUM(CASE WHEN num_days_active_7d > 0 AND num_days_active_21d > num_days_active_7d THEN 1 ELSE 0 END)*100.0/count(1) as pct_21d_active

FROM 
	ahemphill.first_7d_activity_self_paced_instructor_led_summary
GROUP BY
	1,2;

DROP TABLE IF EXISTS ahemphill.duplicate_courses_self_paced_instructor_led;
CREATE TABLE ahemphill.duplicate_courses_self_paced_instructor_led as 
SELECT
	catalog_course_title,
	COUNT(distinct pacing_type)
FROM
(
	SELECT 
		catalog_course_title, 
		pacing_type, 
		COUNT(1) 
	FROM 
		d_course  
	WHERE 
	(
		(datediff('day', start_time,end_time) >= 90 AND pacing_type = 'self_paced')
		OR (datediff('day', start_time,end_time) < 90 AND pacing_type = 'instructor_paced')
	)
	AND end_time <= '2016-12-31'
	GROUP BY
		1,2 
	HAVING 
		(COUNT(1) > 0 AND pacing_type like '%instructor%')
		OR
		(COUNT(1) > 0 AND pacing_type like '%self%')
) a
GROUP BY
	1
HAVING 
	COUNT (distinct pacing_type) > 1;

DROP TABLE IF EXISTS ahemphill.duplicate_courses_self_paced_instructor_led_filtered;
CREATE TABLE ahemphill.duplicate_courses_self_paced_instructor_led_filtered as 
SELECT 
	a.* 
FROM 
	d_course a
JOIN 
	ahemphill.duplicate_courses_self_paced_instructor_led b
on a.catalog_course_title = b.catalog_course_title
WHERE 
(
	(datediff('day', start_time,end_time) >= 90 AND pacing_type = 'self_paced')
	OR (datediff('day', start_time,end_time) < 90 AND pacing_type = 'instructor_paced')
)
AND end_time <= '2016-12-31';

DROP TABLE IF EXISTS ahemphill.duplicate_courses_self_paced_instructor_led_enrollments_over_time;
CREATE TABLE ahemphill.duplicate_courses_self_paced_instructor_led_enrollments_over_time as 
SELECT
	a.course_id,
	a.catalog_course_title,
	a.pacing_type,
	COUNT(1) AS cnt_all_enrolls,
	SUM(CASE WHEN enroll_cohort between 0 and 30 THEN 1 else 0 end) as enroll_30d,
	SUM(CASE WHEN enroll_cohort between 30 and 60 THEN 1 else 0 end) as enroll_60d,
	SUM(CASE WHEN enroll_cohort between 60 and 90 THEN 1 else 0 end) as enroll_90d
FROM
(
SELECT
	a.course_id,
	b.catalog_course_title,
	b.pacing_type,
	a.first_enrollment_time,
	case when enrollment_start_time<start_time then enrollment_start_time else start_time end AS enrollment_start_date,
	datediff('day',case when enrollment_start_time<start_time then enrollment_start_time else start_time end,a.first_enrollment_time) AS enroll_cohort
FROM 
	d_user_course a
JOIN 
	ahemphill.duplicate_courses_self_paced_instructor_led_filtered b
on a.course_id = b.course_id
) a
GROUP BY 1,2,3
