SELECT
	order_org_id,
	SUM(transaction_amount) AS lifetime_bookings,
	SUM(transaction_amount)*100.0/b.overall_lifetime_bookings AS pct_lifetime_bookings,
	SUM(CASE WHEN transaction_date BETWEEN '2015-07-01' AND '2016-07-01' THEN transaction_amount ELSE 0 END) AS FY2016_bookings,
	SUM(CASE WHEN transaction_date BETWEEN '2015-07-01' AND '2016-07-01' THEN transaction_amount ELSE 0 END)*100.0/b.overall_FY2016_bookings AS pct_FY2016_bookings,
	SUM(CASE WHEN transaction_date BETWEEN '2016-07-01' AND '2017-07-01' THEN transaction_amount ELSE 0 END) AS FY2017_bookings,
	SUM(CASE WHEN transaction_date BETWEEN '2016-07-01' AND '2017-07-01' THEN transaction_amount ELSE 0 END) * 100.0/b.overall_FY2017_bookings AS pct_FY2017_bookings
FROM
	finance.f_orderitem_transactions a
JOIN
(
	SELECT
		SUM(transaction_amount) AS overall_lifetime_bookings,
		SUM(CASE WHEN transaction_date BETWEEN '2015-07-01' AND '2016-07-01' THEN transaction_amount ELSE 0 END) AS overall_FY2016_bookings, 
		SUM(CASE WHEN transaction_date BETWEEN '2016-07-01' AND '2017-07-01' THEN transaction_amount ELSE 0 END) AS overall_FY2017_bookings	
	FROM
		finance.f_orderitem_transactions
	WHERE
		order_product_class IN ('seat', 'donation', 'reg-code')
) b
ON 1=1
WHERE
	order_product_class IN ('seat', 'donation', 'reg-code')
GROUP BY
	order_org_id,
	b.overall_lifetime_bookings,
	b.overall_FY2016_bookings,
	b.overall_FY2017_bookings