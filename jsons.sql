SELECT
	JSONB_PRETTY(customer_json)
FROM
	customer_sales
WHERE
	customer_json @> '{"customer_id": 20}'::JSONB;

SELECT
	JSONB_OBJECT_KEYS(customer_json) AS keys,
	customer_json -> JSONB_OBJECT_KEYS(customer_json) AS values
FROM 
	customer_sales
WHERE 
	customer_json @> '{"customer_id":20}'::JSONB;

SELECT
	jsonb_path_exists(customer_json, '$.sales[0]')
FROM 
	customer_sales
LIMIT 
	3;

SELECT
	JSONB_PRETTY(customer_json)
FROM 
	customer_sales
WHERE
	jsonb_path_exists(customer_json, '$.sales[2]')
LIMIT
	2;

SELECT 
  	jsonb_path_query(customer_json, '$.sales[0].sales_amount') AS sales_amount
FROM 
	customer_sales
LIMIT 
	3;

SELECT
	jsonb_path_query_array(customer_json, '$.sales[*].sales_amount ? (@ > 400)') AS result
FROM 
	customer_sales
LIMIT 
	4;

SELECT jsonb_insert('{"a":1,"b":"foo"}', ARRAY['c'], '2');

SELECT jsonb_insert('{"a":1,"b":"foo", "c":[1, 2, 3, 4]}', ARRAY['c', '1'], '10');
SELECT jsonb_insert('{"a":1,"b":"foo", "c":[1, 2, 3, 4]}', ARRAY['d'], '10');

SELECT
	JSONB_ARRAY_ELEMENTS(customer_json -> 'sales') AS sale_json
FROM 
	customer_sales 
LIMIT 
	10;

CREATE TEMP TABLE customer_sales_single_sale_json AS (
	SELECT
    	customer_json,
    	JSONB_ARRAY_ELEMENTS(customer_json -> 'sales') AS sale_json
	FROM 
		customer_sales 
	LIMIT 
		10
);

SELECT 
	DISTINCT JSONB_PRETTY(customer_json)
FROM   
	customer_sales_single_sale_json 
WHERE  
	sale_json ->> 'product_name' = 'Blade';


CREATE TEMP TABLE blade_customer_sales AS (
	SELECT
		jsonb_path_query(customer_json, '$ ? (@.sales[*].product_name == "Blade")') AS customer_json
	FROM 
		customer_sales
);

SELECT 
	JSONB_PRETTY(customer_json) 
FROM 
	blade_customer_sales
LIMIT
	10;
