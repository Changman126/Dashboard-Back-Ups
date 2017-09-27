SELECT
    *,
    CASE 
    WHEN ms_course_program_number::int < 5 THEN 'Unit 1'
    WHEN ms_course_program_number::int < 8 THEN 'Unit 2'
    WHEN ms_course_program_number::int < 11 THEN 'Unit 3'
    ELSE NULL
    END AS ms_course_program_group
FROM
(
SELECT
    a.course_number,
    a.course_id AS lower_course_id,
    b.course_id AS higher_course_id,
    e.program_type,
    e.program_title,
    CASE
        WHEN b.course_id = 'course-v1:Microsoft+DAT101x+2T2017' AND a.course_id = 'course-v1:Microsoft+DAT101x+1T2017' THEN  '1'   
        WHEN b.course_id = 'course-v1:Microsoft+DAT201x+2T2017' AND a.course_id =  'course-v1:Microsoft+DAT201x+1T2017' THEN  '2'   
        WHEN b.course_id = 'course-v1:Microsoft+DAT206x+2T2017' AND a.course_id =  'course-v1:Microsoft+DAT206x+1T2017' THEN  '3'   
        WHEN b.course_id = 'course-v1:Microsoft+DAT207x+2T2017' AND a.course_id =  'course-v1:Microsoft+DAT207x+1T2017' THEN  '3'   
        WHEN b.course_id = 'course-v1:Microsoft+DAT222x+2T2017' AND a.course_id = 'course-v1:Microsoft+DAT222x+1T2017'  THEN  '4'
        WHEN b.course_id = 'course-v1:Microsoft+DAT204x+2T2017' AND a.course_id =  'course-v1:Microsoft+DAT204x+1T2017' THEN  '5'   
        WHEN b.course_id = 'course-v1:Microsoft+DAT208x+2T2017' AND a.course_id =  'course-v1:Microsoft+DAT208x+1T2017' THEN  '5'   
        WHEN b.course_id = 'course-v1:Microsoft+DAT203.1x+2T2017' AND a.course_id = 'course-v1:Microsoft+DAT203.1x+1T2017'   THEN  '6' 
        WHEN b.course_id = 'course-v1:Microsoft+DAT203.2x+2T2017' AND a.course_id = 'course-v1:Microsoft+DAT203.2x+1T2017'   THEN  '7' 
        WHEN b.course_id = 'course-v1:Microsoft+DAT209x+2T2017' AND a.course_id =  'course-v1:Microsoft+DAT209x+1T2017' THEN  '8'   
        WHEN b.course_id = 'course-v1:Microsoft+DAT210x+2T2017' AND a.course_id =  'course-v1:Microsoft+DAT210x+1T2017' THEN  '8'   
        WHEN b.course_id = 'course-v1:Microsoft+DAT203.3x+2T2017' AND a.course_id = 'course-v1:Microsoft+DAT203.3x+1T2017'   THEN  '9' 
        WHEN b.course_id = 'course-v1:Microsoft+DAT211x+2T2017' AND a.course_id =  'course-v1:Microsoft+DAT211x+1T2017' THEN  '9'   
        WHEN b.course_id = 'course-v1:Microsoft+DAT202.3x+2T2017' AND a.course_id ='course-v1:Microsoft+DAT202.3x+1T2017'   THEN  '9' 
        WHEN b.course_id = 'course-v1:Microsoft+DAT213x+3T2017' AND a.course_id =  'course-v1:Microsoft+DAT213x+3T2017' THEN  '9'   
        WHEN b.course_id = 'course-v1:Microsoft+DAT102x+1T2017' AND a.course_id =  'course-v1:Microsoft+DAT102x+1T2017' THEN  '10'  
        WHEN b.course_id = 'course-v1:Microsoft+DAT102x+2T2017'  AND a.course_id = 'course-v1:Microsoft+DAT102x+1T2017' THEN '10'
        ELSE NULL
        END AS ms_course_program_number,
    e.program_slot_number::varchar,
    a.pacing_type,
    a.course_partner,
    a.course_subject,
    a.level_type,
    a.course_verification_end_date AS lower_course_verification_end_date, 
    b.course_verification_end_date AS higher_course_verification_end_date,
    a.course_seat_price AS lower_course_price,
    b.course_seat_price AS higher_course_price,
    (b.course_seat_price - a.course_seat_price) AS price_difference,
    c.sum_enrolls_vtr AS lower_course_enrolls,
    c.sum_verifications AS lower_course_verifications,
    c.sum_bookings AS lower_course_bookings,
    c.vtr * 100.0 AS lower_course_vtr,
    d.sum_enrolls_vtr AS higher_course_enrolls,
    d.sum_verifications AS higher_course_verifications,
    (d.sum_verifications - f.cnt_discounted_verifications) AS higher_course_verifications_minus_vouchers,
    d.sum_bookings AS higher_course_bookings,
    d.vtr * 100.0 AS higher_course_vtr,
    ((d.sum_verifications - COALESCE(f.cnt_discounted_verifications, 0))*100.0/(d.sum_enrolls_vtr - COALESCE(f.cnt_discounted_verifications, 0))) AS undiscounted_vtr,
    (b.course_seat_price - a.course_seat_price) * 100.0/(a.course_seat_price) AS pct_difference_price,
    (d.vtr - c.vtr)*100.0/(c.vtr) AS pct_difference_vtr,
    (((d.sum_verifications - COALESCE(f.cnt_discounted_verifications, 0))/(d.sum_enrolls_vtr - COALESCE(f.cnt_discounted_verifications, 0))) - c.vtr)*100.0/(c.vtr) AS pct_difference_undiscounted_vtr,
    ((d.vtr - c.vtr)/(c.vtr)) / ((b.course_seat_price - a.course_seat_price)/(a.course_seat_price)) AS price_elasticity,
    c.vtr * a.course_seat_price AS expected_value_lower,
    d.vtr * b.course_seat_price AS expected_value_higher,
    d.vtr * g.avg_transaction_amount AS expected_value_higher_actual_price,
    ((d.sum_verifications - COALESCE(f.cnt_discounted_verifications, 0))/(d.sum_enrolls_vtr - COALESCE(f.cnt_discounted_verifications, 0))) * b.course_seat_price AS expected_value_higher_undiscounted,
    ((d.vtr * b.course_seat_price) - (c.vtr * a.course_seat_price)) *100.0 / (c.vtr * a.course_seat_price) AS pct_difference_expected_value,
    ((d.vtr * g.avg_transaction_amount) - (c.vtr * a.course_seat_price)) *100.0 / (c.vtr * a.course_seat_price) AS pct_difference_expected_value_actual_price,
    ((((d.sum_verifications - COALESCE(f.cnt_discounted_verifications, 0))/(d.sum_enrolls_vtr - COALESCE(f.cnt_discounted_verifications, 0))) * b.course_seat_price) - (c.vtr * a.course_seat_price)) *100.0 / (c.vtr * a.course_seat_price) AS pct_difference_expected_value_undiscounted,
    CASE WHEN (b.course_seat_price)/(a.course_seat_price) * (d.vtr)/(c.vtr) < 1 THEN 1 ELSE 0 END AS is_worse,
    CASE 
        WHEN a.course_verification_end_date > b.course_verification_end_date THEN YEAR(a.course_verification_end_date)
        ELSE YEAR(b.course_verification_end_date)
    END AS year
FROM
    business_intelligence.course_master a
JOIN
    business_intelligence.course_master b
ON
    a.course_number = b.course_number
AND
    a.course_id != b.course_id
AND
    a.course_verification_end_date <= CURRENT_DATE()
AND
    b.course_verification_end_date <= CURRENT_DATE()
AND
    a.is_wl = 0
AND
    ABS(DATEDIFF('day', a.course_verification_end_date, b.course_verification_end_date)) < 364
AND
    (b.course_seat_price - a.course_seat_price) >= 5
AND
    a.pacing_type = b.pacing_type
AND
    a.level_type = b.level_type
JOIN
    business_intelligence.course_stats_summary c
ON
    a.course_id = c.course_id
AND
    c.sum_enrolls > 200
JOIN
    business_intelligence.course_stats_summary d
ON
    b.course_id = d.course_id
AND
    d.sum_enrolls > 200
LEFT JOIN
    production.d_program_course e
ON
    a.course_id = e.course_id
LEFT JOIN
(
    SELECT
        course_id,
        COUNT(1) as cnt_discounted_verifications
    FROM 
        business_intelligence.voucher_redemption
    WHERE 
        voucher_code = 'MPP50'
    GROUP BY 
        course_id
) f
ON
    b.course_id = f.course_id
LEFT JOIN
(
    select order_course_id AS course_id, avg(transaction_amount) AS avg_transaction_amount
    from finance.f_orderitem_transactions
    where order_course_id IN
    (
    'course-v1:Microsoft+DAT202.3x+2T2017',
    'course-v1:Microsoft+DAT203.3x+2T2017',
    'course-v1:Microsoft+DAT211x+2T2017',
    'course-v1:Microsoft+DAT209x+2T2017',
    'course-v1:Microsoft+DAT210x+2T2017',
    'course-v1:Microsoft+DAT203.2x+2T2017',
    'course-v1:Microsoft+DAT203.1x+2T2017',
    'course-v1:Microsoft+DAT204x+2T2017',
    'course-v1:Microsoft+DAT208x+2T2017',
    'course-v1:Microsoft+DAT206x+2T2017',
    'course-v1:Microsoft+DAT207x+2T2017',
    'course-v1:Microsoft+DAT201x+2T2017',
    'course-v1:Microsoft+DAT101x+2T2017'

    ) 
    and transaction_date is not null
    and transaction_type = 'sale'
    and order_product_class = 'seat'
    and order_voucher_code IN ('', 'MPP50')
    group by 1
) g
ON
    b.course_id = g.course_id
) a