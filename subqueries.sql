SELECT
	c.id,
	c.name
FROM
	customer AS c
WHERE
	id IN (
		SELECT
			customer_id	
		FROM
			complaint
		WHERE
			is_resolved = FALSE
	);

SELECT
	c.id,
	c.name
FROM
	customer AS c
WHERE
	EXISTS (
		SELECT
			customer_id	
		FROM
			complaint
		WHERE
			customer_id = c.id AND is_resolved = FALSE
	);

SELECT
	co.id,
	g.gender
FROM
	customer_order AS co
CROSS JOIN (
	SELECT DISTINCT
		gender
	FROM
		product
) AS g;

SELECT
	cg.id,
	cg.gender,
	SUM(oi.amount) AS amount_sum
FROM (
	SELECT
		co.id, 
		g.gender
	FROM 
		customer_order AS co
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
GROUP BY cg.id, cg.gender;

SELECT
	cg.*,
	p.*
FROM (
	SELECT
		co.id, 
		g.gender
	FROM 
		customer_order AS co
	CROSS JOIN (
		SELECT DISTINCT
			gender
		FROM 
			product
	) AS g
) AS cg
INNER JOIN 
	product AS p ON p.gender = cg.gender;

SELECT
	cg.id AS cg_order_id,  cg.gender AS cg_gender,
	p.id AS p_product_id, p.gender AS pro_gender,
	oi.order_id AS oi_order_id, oi.product_id AS oi_product_id, oi.amount AS amount
FROM (
	SELECT co.id, g.gender
	FROM  customer_order AS co
	CROSS JOIN (
		SELECT DISTINCT gender
		FROM  product
	) AS g
) AS cg
INNER JOIN product AS p ON p.gender = cg.gender
LEFT OUTER JOIN order_item AS oi ON oi.order_id = cg.id AND oi.product_id = p.id;


SELECT
	*
FROM
	CROSSTAB (
$$
SELECT
	cg.id,
	cg.gender,
	COALESCE(SUM(oi.amount), 0) AS amount_sum
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
	cg.id, cg.gender
ORDER BY 
	cg.id, cg.gender
$$
	) AS ct (
		id INTEGER,
		f_sum NUMERIC(15, 2),
		m_sum NUMERIC(15, 2),
		u_sum NUMERIC(15, 2)
	);

SELECT
	customer_order.id AS order_id,
	max_expensive.product_id,
	max_expensive.amount
FROM
	customer_order
INNER JOIN LATERAL (
	SELECT
		product_id,
		amount
	FROM
		order_item
	WHERE
		order_id = customer_order.id
	ORDER BY 
		amount DESC
	LIMIT 
		1
) AS max_expensive ON TRUE;

SELECT
	c.name AS customer_name,
	c.email AS customer_email,
	o.total_orders
FROM
	customer AS c
INNER JOIN (
	SELECT
		customer_id,
		COUNT(*) AS total_orders
	FROM
		customer_order
	GROUP BY
		customer_id
) AS o ON o.customer_id = c.id;

