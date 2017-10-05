CREATE TABLE IF NOT EXISTS business_intelligence.finance_audit
(
    error_report_date DATE,
    partner_short_code VARCHAR(10),
    month TIMESTAMP,
    num_errors INT,
    net_error_bookings NUMERIC(12,2),
    gross_error_bookings NUMERIC(12,2)
);

DELETE FROM business_intelligence.finance_audit WHERE error_report_date = CURRENT_DATE();

INSERT INTO business_intelligence.finance_audit
SELECT
    CURRENT_DATE() AS error_report_date,
    'edx' AS partner_short_code,
    DATE_TRUNC('month', COALESCE(transaction_date::TIMESTAMP, order_timestamp)) AS month,
    COUNT(*) AS num_errors,
    SUM(COALESCE(transaction_amount_per_item, order_line_item_price)) AS net_error_bookings,
    SUM(ABS(COALESCE(transaction_amount_per_item, order_line_item_price))) AS gross_error_bookings
FROM
    finance.f_orderitem_transactions
WHERE
    order_audit_code != 'ORDER_BALANCED'
    AND partner_short_code='edx'
GROUP BY 1, 2, 3
ORDER BY 3 DESC;
