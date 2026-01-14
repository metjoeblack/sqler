
CREATE VIEW v_customer_sales_agg_sales AS (
	SELECT 
		c.city, c.state,
		p.product_type,
		csj.sales_date,
		SUM(csj.sales_amount) AS total_sales
	FROM 
		customer_sales_flattened AS csj
	INNER JOIN 
		customers AS c USING(customer_id)
	INNER JOIN 
		products AS p ON csj.product_id = p.product_id
	GROUP BY 
		c.city, c.state, p.product_type, csj.sales_date
);


