SELECT
	id,
	category_id,
	name,
	price,
	RANK() OVER (ORDER BY price DESC) AS price_rank
FROM
	product
ORDER BY
	price DESC;

SELECT
	id,
	category_id,
	name,
	price,
	RANK() OVER (PARTITION BY category_id ORDER BY price DESC) AS cat_price_rank
FROM
	product
ORDER BY
	category_id, price DESC;

SELECT
	hd.customer_id,
	SUM(it.amount) AS sum_amt,
	DENSE_RANK() OVER ( ORDER BY SUM(it.amount) DESC ) AS amt_rank
FROM
	customer_order AS hd
INNER JOIN 
	order_item AS it ON it.order_id = hd.id
GROUP BY
	hd.customer_id
ORDER BY
	sum_amt DESC;

SELECT
	hd.customer_id,
	SUM(it.amount) AS sum_amt,
	DENSE_RANK() OVER ( ORDER BY SUM(it.amount) DESC ) AS amt_rank
FROM
	customer_order AS hd
INNER JOIN 
	order_item AS it ON it.order_id = hd.id
GROUP BY
	hd.customer_id;

SELECT
	pr.category_id,
	oi.product_id,
	SUM(oi.quantity) AS quan_sum
FROM
	order_item AS oi
INNER JOIN 
	product AS pr ON pr.id = oi.product_id
GROUP BY
	oi.product_id, pr.category_id
ORDER BY
	category_id, quan_sum DESC;


SELECT
	pr.category_id,
	oi.product_id,
	SUM(oi.quantity) AS quan_sum,
	ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY SUM(oi.quantity) DESC) AS row_no
FROM
	order_item AS oi
INNER JOIN 
	product AS pr ON pr.id = oi.product_id
GROUP BY
	oi.product_id, pr.category_id
ORDER BY
	category_id, quan_sum DESC;


SELECT
	category_id,
	product_id
FROM (
	SELECT
		pr.category_id,
		oi.product_id,
		SUM(oi.quantity) AS quan_sum,
		RANK() OVER (PARTITION BY category_id ORDER BY SUM(oi.quantity) DESC) AS row_no
	FROM
		order_item AS oi
	INNER JOIN 
		product AS pr ON pr.id = oi.product_id
	GROUP BY
		oi.product_id, pr.category_id
	ORDER BY
		category_id, quan_sum DESC
)
WHERE row_no = 1;


SELECT
	id,
	name,
	stock,
	LEAD(stock, 1) OVER (ORDER BY stock) AS next_stock,
	LEAD(stock, 2) OVER (ORDER BY stock) AS next_stock_2
FROM
	product
ORDER BY
	stock;

SELECT
	id,
	name,
	stock,
	next_stock,
	(next_stock - stock) AS stock_delta
FROM (
	SELECT
		id,
		name,
		stock,
		LEAD(stock, 1) OVER (ORDER BY stock) AS next_stock
	FROM
		product
	ORDER BY
		stock
);

SELECT
	id,
	name,
	stock,
	LAG(stock, 1) OVER (ORDER BY stock) AS prev_stock,
	LAG(stock, 2) OVER (ORDER BY stock) AS prev_stock_2
FROM
	product
ORDER BY
	stock;

SELECT
	id,
	name,
	price,
	NTILE(3) OVER (ORDER BY price DESC) AS price_cat
FROM
	product
ORDER BY
	price DESC;

SELECT
	id,
	name,
	price,
	NTILE(2) OVER (ORDER BY price DESC) AS price_cat
FROM
	product
ORDER BY
	price DESC;

SELECT
	id,
	name
FROM (
	SELECT
		id,
		name,
		price,
		NTILE(2) OVER (ORDER BY price DESC) AS price_cat
	FROM
		product
)
WHERE price_cat = 1;

SELECT
	id,
	name,
	price,
	FIRST_VALUE(price) OVER (ORDER BY price DESC) AS max_price,
	FIRST_VALUE(price) OVER (ORDER BY price ASC) AS min_price
FROM
	product;

SELECT
	id,
	name,
	price,
	max_price,
	ABS(max_price - price) AS max_delta,
	min_price,
	ABS(min_price - price) AS min_delta
FROM (
	SELECT
		id,
		name,
		price,
		FIRST_VALUE(price) OVER (ORDER BY price DESC) AS max_price,
		FIRST_VALUE(price) OVER (ORDER BY price ASC) AS min_price
	FROM
		product
);

SELECT
	id,
	name,
	category_id,
	price,
	FIRST_VALUE(price) OVER (PARTITION BY category_id ORDER BY price DESC) AS max_price
FROM
	product;

SELECT
	id,
	name,
	category_id,
	price,
	FIRST_VALUE(price) OVER ( PARTITION BY category_id ORDER BY price DESC ) AS max_price
FROM
	product
ORDER BY
	category_id, id;

SELECT
	invoice_id,
	invoice_item_no,
	vat_rate,
	CAST(vat_rate AS VARCHAR(2)) || ' %' AS vat_rate_txt
FROM
	invoice_item;