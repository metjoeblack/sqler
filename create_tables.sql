
CREATE TABLE employee (
	id 				INT PRIMARY KEY,
	name 			VARCHAR(50) NOT NULL,
	country_code 	VARCHAR(3),
	phone 			VARCHAR(20),
	address 		VARCHAR(100) DEFAULT 'Not specified' || TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD'),
	UNIQUE (country_code, phone),
	CONSTRAINT phone_vs_address CHECK (phone <> address),
	CHECK (LENGTH(address) > 10)
);


CREATE TABLE employee_bonus (
	employee_id 	INT,
	bonus_year 		INT,
	bonus_amount 	NUMERIC(12, 2) NOT NULL CHECK(bonus_amount > 0),
	currency 		VARCHAR(3) NOT NULL,
	PRIMARY KEY (employee_id, bonus_year),
	FOREIGN KEY (employee_id) 
		REFERENCES employee(id) 
		ON DELETE SET NULL
		ON UPDATE CASCADE,
	CHECK (currency IN ('USD', 'EUR'))
);


CREATE TABLE employee_bonus_payment (
	employee_id 	INT,
	bonus_year 		INT,
	installment 	INT,
	payment_amount 	NUMERIC(12, 2) NOT NULL CHECK(payment_amount > 0),
	currency 		VARCHAR(3) NOT NULL,
	is_paid 		BOOLEAN NOT NULL,
	payment_date 	DATE NOT NULL,
	PRIMARY KEY (employee_id, bonus_year, installment),
	FOREIGN KEY (employee_id) 
		REFERENCES employee(id) 
		ON DELETE SET NULL 
		ON UPDATE CASCADE,
	FOREIGN KEY (employee_id, bonus_year) 
		REFERENCES employee_bonus(employee_id, bonus_year) 
		ON DELETE SET NULL 
		ON UPDATE CASCADE
);

ALTER TABLE employee 
	ADD COLUMN child_count VARCHAR(3);

ALTER TABLE employee
	ALTER COLUMN child_count SET DATA TYPE INT;

ALTER TABLE employee 
	DROP COLUMN new_child_count;

ALTER TABLE employee
	ALTER COLUMN child_count TYPE INT USING child_count::INT;

ALTER TABLE employee_bonus
	ADD CONSTRAINT employee_bonus_pkey
	PRIMARY KEY (employee_id, bonus_year);

ALTER TABLE employee_bonus
	ADD CONSTRAINT employee_bonus_fkey1
	FOREIGN KEY (employee_id) REFERENCES employee (id)
	ON DELETE SET NULL 
	ON UPDATE CASCADE;

ALTER TABLE employee_bonus
	ADD CONSTRAINT employee_bonus_chk1
	CHECK (currency = 'USD' OR currency = 'EUR');


CREATE TABLE 
	artist (
		id  VARCHAR(10) PRIMARY KEY,
		name VARCHAR(50) NOT NULL,
		bio  VARCHAR(200)
	);

CREATE TABLE 
	theater (
		id VARCHAR(10) PRIMARY KEY,
		name VARCHAR(50) NOT NULL,
		capacity INT NOT NULL
	);

CREATE TABLE 
	member (
		id SERIAL PRIMARY KEY,
		name VARCHAR(50) NOT NULL,
		birthday DATE,
		phone VARCHAR(15),
		email VARCHAR(50) NOT NULL
	);

CREATE TABLE 
	event (
		id 				SERIAL PRIMARY KEY,
		name 			VARCHAR(50) NOT NULL,
		gig_ts  		TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
		theater_id 		VARCHAR(10) NOT NULL,
		artist_id  		VARCHAR(10) NOT NULL,
		is_cancelled 	BOOLEAN 	NOT NULL DEFAULT FALSE,
		FOREIGN KEY (theater_id) REFERENCES theater(id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
		FOREIGN KEY (artist_id) REFERENCES artist(id)
			ON DELETE CASCADE
			ON UPDATE CASCADE
	);

CREATE TABLE 
	event_ticket (
		event_id  	INT 			NOT NULL,
		category 	VARCHAR(1) 		NOT NULL,
		price  		NUMERIC(10, 2) 	NOT NULL,
		currency 	VARCHAR(3) 		NOT NULL DEFAULT 'USD',
		capacity 	INT 			NOT NULL,
		PRIMARY KEY (event_id, category),
		FOREIGN KEY (event_id) REFERENCES event(id)
			ON DELETE CASCADE
			ON UPDATE CASCADE
	);

CREATE TABLE
	ticket_sale_head (
		id 			SERIAL PRIMARY KEY,
		memeber_id 	INT NOT NULL,
		sale_ts 	TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (memeber_id) REFERENCES member(id)
			ON DELETE CASCADE
			ON UPDATE CASCADE
	);

CREATE TABLE
	ticket_sale_item (
		sale_id 		INT 		NOT NULL,
		item_no 		INT 		NOT NULL,
		event_id 		INT 		NOT NULL,
		category 		VARCHAR(1) 	NOT NULL,
		quantity 		INT 		NOT NULL,
		is_returned 	BOOLEAN 	NOT NULL DEFAULT FALSE,
		PRIMARY KEY (sale_id, item_no),
		FOREIGN KEY (sale_id) REFERENCES ticket_sale_head(id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
		FOREIGN KEY (event_id) REFERENCES event(id)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
		FOREIGN KEY (event_id, category) REFERENCES event_ticket(event_id, category)
			ON DELETE CASCADE
			ON UPDATE CASCADE
	);

ALTER SCHEMA harmony_grarden 
	RENAME TO harmony_garden;

ALTER TABLE employee_bonus
	ADD CONSTRAINT employee_bonus_pkey
	PRIMARY KEY (employee_id, bonus_year);

ALTER TABLE theater
	ADD CONSTRAINT theater_capacity_range
	CHECK(capacity > 0);

ALTER TABLE member
	ADD CONSTRAINT memeber_birthday_range
	CHECK(EXTRACT(YEAR FROM birthday) > '1900');

ALTER TABLE event_ticket
	ADD CONSTRAINT event_ticket_price_range
	CHECK(price > 0);

ALTER TABLE event_ticket
	ADD CONSTRAINT event_ticket_capacity_range
	CHECK(capacity > 0);

ALTER TABLE ticket_sale_item
	ADD CONSTRAINT ticket_sale_item_quantity_range
	CHECK(quantity > 0);

CREATE TABLE
    product_cat (
        id      VARCHAR(10) PRIMARY KEY,
        name    VARCHAR(50) NOT NULL
    );


CREATE TABLE
    product (
        id          VARCHAR(20) 	PRIMARY KEY,
        name        VARCHAR(50)     NOT NULL,
        category_id VARCHAR(10)     NOT NULL,
        gender      CHAR(1)         NOT NULL,
        price       NUMERIC(15, 2)  NOT NULL,
        stock       INT             NOT NULL,
        FOREIGN KEY (category_id) REFERENCES product_cat (id)
        	ON DELETE CASCADE ON UPDATE CASCADE
    );

CREATE TABLE
	customer (
		id 			INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
		name 		VARCHAR(50) 	NOT NULL,
		email 		VARCHAR(50) 	NOT NULL,
		phone 		VARCHAR(50),
		mobile	 	VARCHAR(50),
		address 	VARCHAR(200) 	NOT NULL,
		is_active 	BOOLEAN 		NOT NULL,
		referrer_id INT REFERENCES customer (id)
	);


CREATE TABLE
	customer_order (
		id 				SERIAL PRIMARY KEY,
		customer_id 	INT 		NOT NULL,
		order_ts 		TIMESTAMP 	NOT NULL,
		is_gift 		BOOLEAN 	NOT NULL,
		custom_note 	VARCHAR(100),
		req_dlv_date 	DATE,
		FOREIGN KEY (customer_id) REFERENCES customer (id)
			ON DELETE SET NULL 
			ON UPDATE CASCADE
	);


CREATE TABLE
	order_item (
		order_id 		INT 			NOT NULL,
		order_item_no 	INT 			NOT NULL,
		product_id 		VARCHAR(20) 	NOT NULL,
		quantity 		INT 			NOT NULL,
		price 			NUMERIC(15, 2) 	NOT NULL CHECK(price > 0),
		amount 			NUMERIC(15, 2) 	NOT NULL CHECK(amount > 0),
		PRIMARY KEY (order_id, order_item_no),
		FOREIGN KEY (order_id) REFERENCES customer_order (id) 
			ON DELETE SET NULL ON UPDATE CASCADE,
		FOREIGN KEY (product_id) REFERENCES product (id) 
			ON DELETE SET NULL ON UPDATE CASCADE
	);


CREATE TABLE
	delivery (
		id 			SERIAL PRIMARY KEY,
		delivery_ts TIMESTAMP 	NOT NULL,
		is_shipped 	BOOLEAN 	NOT NULL,
		track_url 	VARCHAR(200),
		customer_id INT 		NOT NULL REFERENCES customer (id)
	);


CREATE TABLE
	delivery_item (
		delivery_id 		INT NOT NULL REFERENCES delivery (id),
		delivery_item_no 	INT NOT NULL,
		order_id 			INT NOT NULL,
		order_item_no 		INT NOT NULL,
		dlv_quantity 		INT NOT NULL,
		PRIMARY KEY (delivery_id, delivery_item_no),
		CONSTRAINT fk_order_item FOREIGN KEY (order_id, order_item_no) 
			REFERENCES order_item (order_id, order_item_no)
	);

CREATE TABLE
	invoice (
		id 			SERIAL 		PRIMARY KEY,
		invoice_ts 	TIMESTAMP 	NOT NULL,
		is_sent 	BOOLEAN 	NOT NULL,
		customer_id INT 		NOT NULL REFERENCES customer (id)
	);

CREATE TABLE
	invoice_item (
		invoice_id 			INT 			NOT NULL REFERENCES invoice (id),
		invoice_item_no 	INT 			NOT NULL,
		delivery_id 		INT 			NOT NULL,
		delivery_item_no 	INT 			NOT NULL,
		amount 				NUMERIC(15, 2) 	NOT NULL,
		vat_rate 			NUMERIC(5, 2) 	NOT NULL,
		vat_amount 			NUMERIC(5, 2) 	NOT NULL,
		total_amount 		NUMERIC(5, 2) 	NOT NULL,
		PRIMARY KEY (invoice_id, invoice_item_no),
		CONSTRAINT fk_delivery_item FOREIGN KEY (delivery_id, delivery_item_no)
			REFERENCES delivery_item (delivery_id, delivery_item_no)
	);

CREATE TABLE 
	complaint (
		id 				SERIAL 		NOT NULL PRIMARY KEY,
		customer_id 	INTEGER 	NOT NULL REFERENCES customer (id),
		order_id 		INTEGER REFERENCES customer_order (id),
		complaint_ts 	TIMESTAMP 	NOT NULL,
		subject 		CHARACTER VARYING(50),
		description 	CHARACTER VARYING(200),
		is_resolved 	BOOLEAN 	NOT NULL
	);


CREATE TABLE customer_sales_flattened AS
	SELECT 
		(csj.customer_json -> 'customer_id')::INTEGER AS customer_id,
		(csj.customer_json ->> 'first_name') AS first_name,
		(csj.customer_json ->> 'last_name') AS last_name,
		(csj.customer_json ->> 'email') AS email,
		(csj.customer_json ->> 'phone') AS phone,
		(JSONB_ARRAY_ELEMENTS(csj.customer_json -> 'sales') -> 'product_id')::INTEGER AS product_id,
		(JSONB_ARRAY_ELEMENTS(csj.customer_json -> 'sales') ->> 'product_name') AS product_name,
		(JSONB_ARRAY_ELEMENTS(csj.customer_json -> 'sales') -> 'sales_amount')::NUMERIC(10, 2) AS sales_amount,
		TO_TIMESTAMP(
			(JSONB_ARRAY_ELEMENTS(csj.customer_json -> 'sales') ->> 'sales_transaction_date'), 
			'YYYY-MM-DDXHH24:MI:SS'
		) AS sales_date
	FROM customer_sales_json csj;

SELECT
	csj.customer_json -> 'sales' AS sales
FROM
	customer_sales_json AS csj;
	

