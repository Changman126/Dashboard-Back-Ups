--distinct users enrolled in GFA


SELECT
	COUNT(1),
	COUNT(DISTINCT user_id)
FROM
	production.d_user_course
WHERE
	course_id IN
	(
'course-v1:ASUx+ASM246+1T2016',
'course-v1:ASUx+ASM246+2167A',
'course-v1:ASUx+ASM246+2171A',
'course-v1:ASUx+ASM246+2174C',
'course-v1:ASUx+ASM246+3T2015',
'course-v1:ASUx+AST111+3T2015',
'course-v1:ASUx+AST111x+1T2016',
'course-v1:ASUx+AST111x+2161B',
'course-v1:ASUx+AST111x+2164C',
'course-v1:ASUx+AST111x+2167B',
'course-v1:ASUx+AST111x+2171B',
'course-v1:ASUx+AST111x+2174C',
'course-v1:ASUx+CEE181x+1T2016',
'course-v1:ASUx+CEE181x+2164C',
'course-v1:ASUx+CEE181x+2171A',
'course-v1:ASUx+CEE181x+2177A',
'course-v1:ASUx+ECN211+3T2016',
'course-v1:ASUx+ECN211x+2167B',
'course-v1:ASUx+ECN211x+2171B',
'course-v1:ASUx+ECN211x+2177A',
'course-v1:ASUx+ENG101x+1T2016',
'course-v1:ASUx+ENG101x+2167A',
'course-v1:ASUx+ENG101x+2171A',
'course-v1:ASUx+ENG101x+2174C',
'course-v1:ASUx+ENG102x+2167B',
'course-v1:ASUx+ENG102x+2171B',
'course-v1:ASUx+ENG102x+2177B',
'course-v1:ASUx+ENG102x+3T2016',
'course-v1:ASUx+EXW100x+1T2016',
'course-v1:ASUx+EXW100x+2164C',
'course-v1:ASUx+EXW100x+2167B',
'course-v1:ASUx+EXW100x+2171B',
'course-v1:ASUx+EXW100x+2177B',
'course-v1:ASUx+HST102+3T2015',
'course-v1:ASUx+HST102x+1T2016',
'course-v1:ASUx+HST102x+2164C',
'course-v1:ASUx+HST102x+2167B',
'course-v1:ASUx+HST102x+2171B',
'course-v1:ASUx+HST102x+2177A',
'course-v1:ASUx+MAT117x+1T2016',
'course-v1:ASUx+SOC101X+2167A',
'course-v1:ASUx+SOC101x+2171A',
'course-v1:ASUx+SOC101x+2174C',
'course-v1:ASUx+SOC101x+2T2016'
)
--distinct users enrolled in charter oak
	SELECT COUNT(1),
	COUNT(DISTINCT user_id)
FROM
	production.d_user_course
WHERE
	course_id IN
	(
'course-v1:BerkeleyX+CS169.1x+1T2017SP',
'course-v1:BerkeleyX+CS169.1x+3T2015SP',
'course-v1:BerkeleyX+CS169.2x+1T2016',
'course-v1:BerkeleyX+CS169.2x+1T2016SP',
'course-v1:BerkeleyX+CS169.2x+1T2017SP',
'course-v1:MITx+6.00.1x_11+1T2017',
'course-v1:MITx+6.00.1x_8+1T2016',
'course-v1:MITx+6.00.1x+2T2016',
'course-v1:MITx+6.00.1x+2T2017'
);

--passes per program type, exclude GFA and Charter Oak

SELECT
sum(has_passed),
program_type
FROM production.d_user_course_certificate a 
LEFT JOIN production.d_program_course b
ON a.course_id = b.course_id
WHERE
a.course_id NOT IN
(
'course-v1:BerkeleyX+CS169.1x+1T2017SP',
'course-v1:BerkeleyX+CS169.1x+3T2015SP',
'course-v1:BerkeleyX+CS169.2x+1T2016',
'course-v1:BerkeleyX+CS169.2x+1T2016SP',
'course-v1:BerkeleyX+CS169.2x+1T2017SP',
'course-v1:MITx+6.00.1x_11+1T2017',
'course-v1:MITx+6.00.1x_8+1T2016',
'course-v1:MITx+6.00.1x+2T2016',
'course-v1:MITx+6.00.1x+2T2017',
'course-v1:ASUx+ASM246+1T2016',
'course-v1:ASUx+ASM246+2167A',
'course-v1:ASUx+ASM246+2171A',
'course-v1:ASUx+ASM246+2174C',
'course-v1:ASUx+ASM246+3T2015',
'course-v1:ASUx+AST111+3T2015',
'course-v1:ASUx+AST111x+1T2016',
'course-v1:ASUx+AST111x+2161B',
'course-v1:ASUx+AST111x+2164C',
'course-v1:ASUx+AST111x+2167B',
'course-v1:ASUx+AST111x+2171B',
'course-v1:ASUx+AST111x+2174C',
'course-v1:ASUx+CEE181x+1T2016',
'course-v1:ASUx+CEE181x+2164C',
'course-v1:ASUx+CEE181x+2171A',
'course-v1:ASUx+CEE181x+2177A',
'course-v1:ASUx+ECN211+3T2016',
'course-v1:ASUx+ECN211x+2167B',
'course-v1:ASUx+ECN211x+2171B',
'course-v1:ASUx+ECN211x+2177A',
'course-v1:ASUx+ENG101x+1T2016',
'course-v1:ASUx+ENG101x+2167A',
'course-v1:ASUx+ENG101x+2171A',
'course-v1:ASUx+ENG101x+2174C',
'course-v1:ASUx+ENG102x+2167B',
'course-v1:ASUx+ENG102x+2171B',
'course-v1:ASUx+ENG102x+2177B',
'course-v1:ASUx+ENG102x+3T2016',
'course-v1:ASUx+EXW100x+1T2016',
'course-v1:ASUx+EXW100x+2164C',
'course-v1:ASUx+EXW100x+2167B',
'course-v1:ASUx+EXW100x+2171B',
'course-v1:ASUx+EXW100x+2177B',
'course-v1:ASUx+HST102+3T2015',
'course-v1:ASUx+HST102x+1T2016',
'course-v1:ASUx+HST102x+2164C',
'course-v1:ASUx+HST102x+2167B',
'course-v1:ASUx+HST102x+2171B',
'course-v1:ASUx+HST102x+2177A',
'course-v1:ASUx+MAT117x+1T2016',
'course-v1:ASUx+SOC101X+2167A',
'course-v1:ASUx+SOC101x+2171A',
'course-v1:ASUx+SOC101x+2174C',
'course-v1:ASUx+SOC101x+2T2016'
)

SELECT
sum(has_passed),
program_type,
current_enrollment_mode
FROM production.d_user_course_certificate a 
LEFT JOIN production.d_program_course b
ON a.course_id = b.course_id
JOIN production.d_user_course c
on a.course_id = c.course_id
and a.user_id = c.user_id
WHERE
a.course_id NOT IN
(
'course-v1:BerkeleyX+CS169.1x+1T2017SP',
'course-v1:BerkeleyX+CS169.1x+3T2015SP',
'course-v1:BerkeleyX+CS169.2x+1T2016',
'course-v1:BerkeleyX+CS169.2x+1T2016SP',
'course-v1:BerkeleyX+CS169.2x+1T2017SP',
'course-v1:MITx+6.00.1x_11+1T2017',
'course-v1:MITx+6.00.1x_8+1T2016',
'course-v1:MITx+6.00.1x+2T2016',
'course-v1:MITx+6.00.1x+2T2017',
'course-v1:ASUx+ASM246+1T2016',
'course-v1:ASUx+ASM246+2167A',
'course-v1:ASUx+ASM246+2171A',
'course-v1:ASUx+ASM246+2174C',
'course-v1:ASUx+ASM246+3T2015',
'course-v1:ASUx+AST111+3T2015',
'course-v1:ASUx+AST111x+1T2016',
'course-v1:ASUx+AST111x+2161B',
'course-v1:ASUx+AST111x+2164C',
'course-v1:ASUx+AST111x+2167B',
'course-v1:ASUx+AST111x+2171B',
'course-v1:ASUx+AST111x+2174C',
'course-v1:ASUx+CEE181x+1T2016',
'course-v1:ASUx+CEE181x+2164C',
'course-v1:ASUx+CEE181x+2171A',
'course-v1:ASUx+CEE181x+2177A',
'course-v1:ASUx+ECN211+3T2016',
'course-v1:ASUx+ECN211x+2167B',
'course-v1:ASUx+ECN211x+2171B',
'course-v1:ASUx+ECN211x+2177A',
'course-v1:ASUx+ENG101x+1T2016',
'course-v1:ASUx+ENG101x+2167A',
'course-v1:ASUx+ENG101x+2171A',
'course-v1:ASUx+ENG101x+2174C',
'course-v1:ASUx+ENG102x+2167B',
'course-v1:ASUx+ENG102x+2171B',
'course-v1:ASUx+ENG102x+2177B',
'course-v1:ASUx+ENG102x+3T2016',
'course-v1:ASUx+EXW100x+1T2016',
'course-v1:ASUx+EXW100x+2164C',
'course-v1:ASUx+EXW100x+2167B',
'course-v1:ASUx+EXW100x+2171B',
'course-v1:ASUx+EXW100x+2177B',
'course-v1:ASUx+HST102+3T2015',
'course-v1:ASUx+HST102x+1T2016',
'course-v1:ASUx+HST102x+2164C',
'course-v1:ASUx+HST102x+2167B',
'course-v1:ASUx+HST102x+2171B',
'course-v1:ASUx+HST102x+2177A',
'course-v1:ASUx+MAT117x+1T2016',
'course-v1:ASUx+SOC101X+2167A',
'course-v1:ASUx+SOC101x+2171A',
'course-v1:ASUx+SOC101x+2174C',
'course-v1:ASUx+SOC101x+2T2016'

)
GROUP BY 2,3

'course-v1:MITx+CTL.SC0x+3T2016',
'course-v1:MITx+CTL.SC0x+3T2017',
'course-v1:MITx+CTL.SC0x_2+1T2017',
'course-v1:MITx+CTL.SC1x_1+2T2015',
'course-v1:MITx+CTL.SC1x_1+2T2015',
'course-v1:MITx+CTL.SC1x_2+1T2016',
'course-v1:MITx+CTL.SC1x_2+1T2016',
'course-v1:MITx+CTL.SC1x_3+1T2017',
'course-v1:MITx+CTL.SC1x_3+2T2017',
'course-v1:MITx+CTL.SC1x_3+2T2017',
'course-v1:MITx+CTL.SC2x+3T2015',
'course-v1:MITx+CTL.SC2x+3T2015',
'course-v1:MITx+CTL.SC2x_2+2T2016',
'course-v1:MITx+CTL.SC2x_2+2T2016',
'course-v1:MITx+CTL.SC2x_3+1T2017',
'course-v1:MITx+CTL.SC3x+2T2016',
'course-v1:MITx+CTL.SC3x+2T2016',
'course-v1:MITx+CTL.SC3x+2T2017',
'course-v1:MITx+CTL.SC4x+1T2017',
'course-v1:MITx+CTL.SC4x+3T2017',
'MITx/ESD.SCM1x/3T2014',
'MITx/ESD.SCM1x/3T2014'