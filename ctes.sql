WITH
	order_count AS (
		SELECT
			customer_id,
			COUNT(*) AS total_orders
		FROM
			customer_order
		GROUP BY
			customer_id
	)
SELECT
	c.name AS customer_name,
	c.email AS customer_email,
	o.total_orders
FROM
	customer AS c
INNER JOIN 
	order_count AS o ON o.customer_id = c.id;


SELECT
	cg.id,
	cg.gender,
	SUM(oi.amount) AS amount_sum
FROM (
	SELECT
		customer_order.id,
		g.gender
	FROM
		customer_order
	CROSS JOIN (
		SELECT DISTINCT
			gender
		FROM
			product
	) AS g
) AS cg
INNER JOIN 
	product AS p ON p.gender = cg.gender
LEFT OUTER JOIN 
	order_item AS oi ON oi.order_id = cg.id AND oi.product_id = p.id
GROUP BY 
	cg.id, cg.gender;


WITH
	g AS (
		SELECT DISTINCT
			gender
		FROM
			product
	),
	cg AS (
		SELECT
			customer_order.id,
			g.gender
		FROM
			customer_order
		CROSS JOIN g
	)
SELECT
	cg.id,
	cg.gender,
	SUM(oi.amount) AS amount_sum
FROM
	cg
INNER JOIN 
	product AS p ON p.gender = cg.gender
LEFT OUTER JOIN 
	order_item AS oi ON oi.order_id = cg.id AND oi.product_id = p.id
GROUP BY 
	cg.id, cg.gender;

WITH
	customers_with_phone AS (
		SELECT first_name, last_name, state, email
		FROM customers
		WHERE phone IS NOT NULL 
	)
SELECT
	first_name, last_name, email
	-- COUNT(*)
FROM
	customers_with_phone
WHERE state IN (
		SELECT state FROM dealerships
	);

CREATE VIEW v_reachable_customer AS (
	SELECT first_name, last_name, state, email
	FROM customers
	WHERE phone IS NOT NULL
);


WITH 
	daily_sales as (
		SELECT 
			p.model,
			s.sales_transaction_date::date, 
			SUM(s.sales_amount) sales_amount
		FROM 
			sales AS s
		INNER JOIN 
			products AS p USING(product_id)
		WHERE 
			p.model ILIKE '%limited edition%'
		GROUP BY 
			1, 2
	)
SELECT
	EXTRACT(dow FROM sales_transaction_date) AS day_type,
	AVG(sales_amount) AS avg_sales_amount
FROM 
	daily_sales 
GROUP BY 
	1;

