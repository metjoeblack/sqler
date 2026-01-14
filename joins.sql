SELECT
	o.order_id,
	o.order_item_no,
	o.product_id,
	o.quantity,
	p.name,
	p.category_id
FROM
	order_item AS o
INNER JOIN 
	product AS p ON p.id = o.product_id;


SELECT
	o.order_id,
	o.order_item_no,
	o.product_id,
	d.delivery_id,
	d.delivery_item_no,
	d.dlv_quantity
FROM
	order_item AS o
INNER JOIN 
	delivery_item AS d USING (order_id, order_item_no)
ORDER BY
	o.order_id, o.order_item_no, d.delivery_id, d.delivery_item_no;

SELECT
	o.order_id,
	o.order_item_no,
	o.product_id,
	p.name,
	d.dlv_quantity
FROM
	order_item AS o
INNER JOIN 
	product AS p ON p.id = o.product_id
INNER JOIN 
	delivery_item AS d USING (order_id, order_item_no)
WHERE
	o.quantity > 1
ORDER BY
	o.order_id, o.order_item_no, d.delivery_id, d.delivery_item_no;


SELECT
	-- o.order_id,
	-- o.order_item_no,
	o.product_id AS p_id,
	SUM(d.dlv_quantity) AS d_quantity
FROM
	order_item AS o
INNER JOIN 
	delivery_item AS d USING (order_id, order_item_no)
GROUP BY
	o.order_id, o.order_item_no
ORDER BY
	o.product_id;


SELECT
	o.order_id, o.order_item_no, o.product_id,
	d.delivery_id, d.delivery_item_no, d.dlv_quantity
FROM
	order_item AS o
LEFT OUTER JOIN 
	delivery_item AS d USING (order_id, order_item_no)
ORDER BY
	o.order_id, o.order_item_no, d.delivery_id, d.delivery_item_no;

SELECT
	o.order_id, 
	o.order_item_no,
	p.name AS prod_name,
	d.delivery_id, 
	d.delivery_item_no, 
	d.dlv_quantity
FROM
	order_item AS o
INNER JOIN 
	product AS p ON p.id = o.product_id
LEFT OUTER JOIN 
	delivery_item AS d USING (order_id, order_item_no)
WHERE
	p.name LIKE '%a%e%'
ORDER BY 
	o.order_id, o.order_item_no, d.delivery_id, d.delivery_item_no;


SELECT
	-- SUM(d.dlv_quantity) AS dlv_sum
	AVG(COALESCE(d.dlv_quantity, 0)) AS dlv_avg
FROM
	order_item AS o
INNER JOIN 
	product AS p ON p.id = o.product_id
LEFT OUTER JOIN 
	delivery_item AS d USING (order_id, order_item_no)
WHERE
	p.name LIKE '%a%e%';

SELECT
	c.id,
	c.customer_id AS c_customer,
	c.order_id AS c_order_id,
	c.subject,
	o.id AS o_order_id,
	o.customer_id AS o_customer,
	date (o.order_ts) AS o_date
FROM
	complaint AS c
FULL OUTER JOIN 
	customer_order AS o ON o.id = c.order_id;


SELECT
	c1.id,
	c1.name,
	c1.referrer_id,
	c2.name AS referred_name
FROM
	customer AS c1
LEFT OUTER JOIN
	customer AS c2 ON c1.referrer_id = c2.id;

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


SELECT
	ct.id AS customer_id,
	ct.name,
	co.id AS order_id,
	co.order_ts
FROM
	customer AS ct
LEFT OUTER JOIN
	customer_order AS co ON ct.id = co.customer_id;

SELECT
	c.name AS customer_name,
	recent_orders.order_ts
FROM
	customer AS c
LEFT OUTER JOIN (
	SELECT
		customer_id,
		CAST(order_ts AS date)
	FROM
		customer_order
	WHERE
		order_ts >= NOW() - INTERVAL '1 month'
) AS recent_orders ON c.id = recent_orders.customer_id;


SELECT
	p.category_id,
	ROUND(AVG(o.price), 2) AS avg_price,
	ROUND(AVG(i.vat_amount), 2) AS avg_vat
FROM
	invoice_item AS i
INNER JOIN 
	delivery_item AS d ON d.delivery_id = i.delivery_id AND d.delivery_item_no = i.delivery_item_no
INNER JOIN 
	order_item AS o ON o.order_id = d.order_id AND o.order_item_no = d.order_item_no
INNER JOIN 
	product AS p ON p.id = o.product_id
GROUP BY
	p.category_id;


SELECT
	p.category_id,
	CEILING(AVG(o.price)) AS avg_price,
	CEILING(AVG(i.vat_amount)) AS avg_vat
FROM
	invoice_item AS i
INNER JOIN 
	delivery_item AS d ON d.delivery_id = i.delivery_id AND d.delivery_item_no = i.delivery_item_no
INNER JOIN 
	order_item AS o ON o.order_id = d.order_id AND o.order_item_no = d.order_item_no
INNER JOIN 
	product AS p ON p.id = o.product_id
GROUP BY
	p.category_id;

