SELECT
distinct
a.user_id,
a.course_id,
a.current_enrollment_mode,
a.current_enrollment_is_active
FROM
d_user_course a
join d_user b
on a.user_id = b.user_id
and a.course_id IN
(
'course-v1:HarvardXPLUS+CHNSLITx+3T2016',
'course-v1:HarvardXPLUS+CHNSLITxPLUS+3T2016',
'course-v1:HarvardXPLUS+HKS211xPLUS+3T2016',
'course-v1:HarvardXPLUS+HLS2xPLUS+3T2016',
'course-v1:HarvardXPLUS+HUM12x+3T2016',
'course-v1:HarvardXPLUS+HUM12xPLUS+3T2016',
'course-v1:HarvardXPLUS+MCB63xPLUS+1T2017',
'course-v1:HarvardXPLUS+MCB63xPLUS+3T2016',
'course-v1:harvardx+MCB63xPLUS+1T2017'

)
join finance.f_orderitem_transactions c
on c.order_username = b.user_username
and a.course_id = c.order_course_id
and c.transaction_audit_code = 'PURCHASE_ONE'
