SELECT 
	b.user_id,
	b.user_email
FROM 
	d_user_course_certificate a
JOIN
	d_user b 
ON a.user_id = b.user_id
WHERE 
	course_id IN

(
'course-v1:Wharton+DigitalMarketing1.1x+3T2016',
'course-v1:Wharton+MarketingAnalytics101x+2T2016',
'course-v1:Wharton+CustomerCentricityx+3T2016',
'course-v1:Wharton+SellingIdeas101x+3T2016'

)
GROUP BY 
        1,2
HAVING 
	SUM(has_passed) = 4