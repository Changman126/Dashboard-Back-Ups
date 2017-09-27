select
	a.*
from
	course_master a
JOIN
(
	select
		course_name,
		max(course_run_number) AS course_run_number
	from 
		course_master 
	where 
		lower(course_number) LIKE '%d001x%' or
		lower(course_number) LIKE '%bio465x%' or
		lower(course_number) LIKE '%infx523-01x%' or
		lower(course_number) LIKE '%15.s23x%' or
		lower(course_number) LIKE '%15.390.2x%' or
		lower(course_number) LIKE '%2.01x%' or
		lower(course_number) LIKE '%2.03x%' or
		lower(course_number) LIKE '%16.101x%' or
		lower(course_number) LIKE '%6.041x%' or
		lower(course_number) LIKE '%6.00.2x%' or
		lower(course_number) LIKE '%6.00.1x%' or
		lower(course_number) LIKE '%15.390x%' or
		lower(course_number) LIKE '%6.002x%' or
		lower(course_number) LIKE '%2.01x%' or
		lower(course_number) LIKE '%chem181x%' or
		lower(course_number) LIKE '%atoc185x%' or
		lower(course_number) LIKE '%meddigx%' or
		lower(course_number) LIKE '%advbio.4x%' or
		lower(course_number) LIKE '%advbio.5x%' or
		lower(course_number) LIKE '%advensci.4x%' or
		lower(course_number) LIKE '%reli154x%' or
		lower(course_number) LIKE '%advensci.3x%' or
		lower(course_number) LIKE '%advbio.3x%' or
		lower(course_number) LIKE '%advensci.2x%' or
		lower(course_number) LIKE '%bioc372.2x%' or
		lower(course_number) LIKE '%advbio.2x%' or
		lower(course_number) LIKE '%advbio.1x%' or
		lower(course_number) LIKE '%advensci.1x%' or
		lower(course_number) LIKE '%bioc372.1x%' or
		lower(course_number) LIKE '%phys102x%' or
		lower(course_number) LIKE '%phys102.1x%' or
		lower(course_number) LIKE '%wine101x%' or
		lower(course_number) LIKE '%humbio101x%' or
		lower(course_number) LIKE '%colwri2.3x%' or
		lower(course_number) LIKE '%colwri2.2x%' or
		lower(course_number) LIKE '%colwri2.1x%' or
		lower(course_number) LIKE '%cs184.1x%' or
		lower(course_number) LIKE '%cs169.2x%' or
		lower(course_number) LIKE '%cs169.1x%' or
		lower(course_number) LIKE '%cse167x%' or
		lower(course_number) LIKE '%crime101x%' or
		lower(course_number) LIKE '%write101x%' or
		lower(course_number) LIKE '%bioimg101x%' or
		lower(course_number) LIKE '%tropic101x%' or
		lower(course_number) LIKE '%think101x%' or
		lower(course_number) LIKE '%nutr101x%' or
		lower(course_number) LIKE '%hist229x%' or
		lower(course_number) LIKE '%anth207x%' or
		lower(course_number) LIKE '%et3034x%'
	-- AND
	-- 	course_reporting_type = 'mooc'
	group by 
		1
) b
ON
	a.course_name = b.course_name
AND
	a.course_run_number = b.course_run_number
-- AND
-- 	a.course_reporting_type = 'mooc'