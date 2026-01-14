
CREATE OR REPLACE PROCEDURE create_mock_ticket_data()
LANGUAGE plpgsql AS $$
BEGIN
	DELETE FROM ticket_sale_item CASCADE;
	DELETE FROM ticket_sale_head CASCADE;
	ALTER SEQUENCE ticket_sale_head_id_seq RESTART WITH 1;

	INSERT INTO ticket_sale_head (member_id, sale_ts)
		SELECT 
			id, 
			CURRENT_TIMESTAMP AS sales_ts
		FROM member
		ORDER BY NAME LIMIT 3;

	WITH 
	    ranked_events AS (
	        SELECT
	            id AS event_id,
	            ROW_NUMBER() OVER (ORDER BY id) AS rn
	        FROM event
	    ),
	    expanded_sales AS (
	        SELECT
	            id AS sale_id,
	            ROW_NUMBER() OVER (ORDER BY id) * 2 - 1 AS rn1,
	            ROW_NUMBER() OVER (ORDER BY id) * 2 AS rn2
	        FROM ticket_sale_head
	    )

	INSERT INTO ticket_sale_item (sale_id, item_no, event_id, category, quantity)
		SELECT 
			es.sale_id, 1, re1.event_id, 'B', 1
		FROM 
			expanded_sales AS es INNER JOIN ranked_events AS re1 ON es.rn1 = re1.rn
		UNION ALL
		SELECT 
			es.sale_id, 2, re2.event_id, 'C', 3
		FROM 
			expanded_sales AS es INNER JOIN ranked_events AS re2 ON es.rn2 = re2.rn;
END; $$


CALL create_mock_ticket_data();

CREATE OR REPLACE PROCEDURE add_theater_row (
	theater_id 			VARCHAR(10),
	theater_name 		VARCHAR(50),
	theater_capacity 	INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
	INSERT INTO theater(id, name, capacity)
		VALUES (theater_id, theater_name, theater_capacity);

	IF length(theater_name) < 5 THEN
		RAISE EXCEPTION 'Theater name too short';
	END IF;

	EXCEPTION
		WHEN unique_violation
		THEN RAISE NOTICE 'The theater already exists';
END; 
$$
;

CALL add_theater_row('LUNA', 'Luna Vista', 500);


CREATE OR REPLACE PROCEDURE reset_and_populate_bank_data ()
LANGUAGE plpgsql AS $$
BEGIN
	-- Truncate tables and reset serials
	TRUNCATE TABLE transaction, credit_card, customer_acc, bank_customer, bank_day_sum RESTART IDENTITY CASCADE;

	-- Insert mock data into bank_customer
	INSERT INTO bank_customer (name, phone, email) 
	VALUES
		('John Doe', '123-456-7890', 'john.doe@example.com'),
		('Jane Smith', '234-567-8901', 'jane.smith@example.com'),
		('Alice Johnson', '345-678-9012', 'alice.johnson@example.com');

	-- Insert mock data into customer_acc
	INSERT INTO customer_acc (customer_id, is_active, under_review, balance, currency)
	VALUES
		(1, TRUE, FALSE, 10000.00, 'USD'),
		(2, TRUE, TRUE, 5000.00, 'USD'),
		(3, FALSE, FALSE, 7500.00, 'EUR');

	-- Insert mock data into credit_card
	INSERT INTO credit_card (
		card_number, customer_id, card_network, expiration_day, 
		cvv, card_limit, usable_limit, currency
	)
	VALUES
		('1234567812345678', 1, 'VISA', '2026-01-01', '123', 5000.00, 4500.00, 'USD'),
		('2345678923456789', 2, 'MASTER', '2025-12-01', '456', 3000.00, 2800.00, 'USD'),
		('3456789034567890', 3, 'AMEX', '2027-03-15', '789', 7000.00, 7000.00, 'EUR');

	-- Insert mock data into transaction
	INSERT INTO transaction (
		transaction_type, from_acc, to_acc, from_credit_card, 
		to_credit_card, amount, currency, trans_ts
	)
	VALUES
		('TRA', 1, 2, NULL, NULL, 1500.00, 'USD', '2024-09-02 16:30:00'),
		('CRD', 2, NULL, NULL, '2345678923456789', 5.00, 'USD', '2024-09-03 10:00:00'),
		('TRA', 3, 1, NULL, NULL, 300.00, 'EUR', '2024-09-04 14:14:00');
	
	-- Insert mock data into bank_day_sum
	INSERT INTO bank_day_sum (day, currency, account_balance, usable_card_limit, total_transaction)
	VALUES
		('2024-01-01', 'USD', 15000.00, 7300.00, 2000.00),
		('2024-01-01', 'EUR', 7500.00, 7000.00, 300.00);
END;
$$
;

CREATE OR REPLACE PROCEDURE do_money_transfer (
    source_acc      INT,
    target_acc      INT,
    trn_amount      NUMERIC(15, 2),
    trn_currency    VARCHAR(3),
    time_stamp      TIMESTAMP
)
LANGUAGE plpgsql AS $$
DECLARE updated_row_count INTEGER;
BEGIN
    -- Update source account
    UPDATE customer_acc 
        SET balance = balance - trn_amount
        WHERE id = source_acc AND currency = trn_currency;

    GET DIAGNOSTICS updated_row_count = ROW_COUNT;

    IF updated_row_count < 1 THEN
        ROLLBACK;
        RAISE EXCEPTION 'Invalid source account';
    END IF;

    -- Update target account
    UPDATE customer_acc 
        SET balance = balance + trn_amount
        WHERE id = target_acc AND currency = trn_currency;
    
    GET DIAGNOSTICS updated_row_count = ROW_COUNT;
    
    IF updated_row_count < 1 THEN
        ROLLBACK;
        RAISE EXCEPTION 'Invalid target account';
    END IF;
    
    -- Record transaction
    INSERT INTO transaction(transaction_type, from_acc, to_acc, amount, currency, trans_ts)
    VALUES 
        ('TRA', source_acc, target_acc, trn_amount, trn_currency, time_stamp);
    
    -- Finish transaction
    COMMIT;
END; 
$$
;

BEGIN;
    INSERT INTO bank_customer (name, phone) VALUES 
        ('Sarah Livingston', '+1-555-897-2341');

    INSERT INTO bank_customer (name, phone) VALUES 
        ('Michael Thompson', '+1-555-762-1943');

    INSERT INTO bank_customer (name,phone) VALUES 
        ('Emma Reynolds', '+1-555-348-7265');
COMMIT;

BEGIN;
    INSERT INTO bank_customer (name, phone) VALUES 
        ('Sarah Livingston', '+1-555-897-2341');

    INSERT INTO bank_customer (name, phone) VALUES 
        ('Michael Thompson', '+1-555-762-1943');

    INSERT INTO bank_customer (name,phone) VALUES 
        ('Emma Reynolds', '+1-555-348-7265');
ROLLBACK;


CALL reset_and_populate_bank_data();

BEGIN;
    -- Customer 1
    INSERT INTO bank_customer (NAME,phone) VALUES 
        ('Sarah Livingston', '+1-555-897-2341');
    SAVEPOINT first_customer;

    -- Customer 2
    INSERT INTO bank_customer (NAME,phone) VALUES 
        ('Michael Thompson', '+1-555-762-1943');
    SAVEPOINT second_customer;

    -- Customer 3
    INSERT INTO bank_customer (NAME,phone) VALUES 
        ('Emma Reynolds', '+1-555-348-7265');
    SAVEPOINT third_customer;
    -- Finish
COMMIT;

CALL reset_and_populate_bank_data ();

BEGIN;
    -- Customer 1
    INSERT INTO bank_customer (name,phone) VALUES 
        ('Sarah Livingston', '+1-555-897-2341');
    SAVEPOINT first_customer;

    -- Customer 2
    INSERT INTO bank_customer (name,phone) VALUES 
        ('Michael Thompson', '+1-555-762-1943');
    SAVEPOINT second_customer;

    -- Customer 3
    INSERT INTO bank_customer (name,phone) VALUES 
        ('Emma Reynolds', '+1-555-348-7265');
    SAVEPOINT third_customer;

    -- Finish
    ROLLBACK TO second_customer;
COMMIT;

BEGIN;
    SELECT * FROM bank_customer WHERE id = 1 FOR UPDATE;

    UPDATE bank_customer
        SET phone = '+1-555-849-6237'
        WHERE id = 1;
COMMIT;

BEGIN;
    SELECT * FROM credit_card WHERE customer_id = 1 FOR UPDATE;

    UPDATE credit_card
        SET usable_limit = usable_limit * 1.25
        WHERE customer_id = 1;
COMMIT;

BEGIN;
    SELECT * FROM bank_day_sum
        WHERE day = CURRENT_DATE AND currency = 'EUR' FOR UPDATE;
    
    DELETE FROM bank_day_sum 
        WHERE day = CURRENT_DATE AND currency = 'EUR';
COMMIT;


BEGIN;
    LOCK TABLE customer_acc IN EXCLUSIVE MODE;
-- Further SQL statements
COMMIT;

BEGIN;
    LOCK TABLE credit_card IN EXCLUSIVE MODE;
    ALTER TABLE credit_card ADD COLUMN is_active BOOLEAN;
COMMIT;

BEGIN;
    LOCK TABLE customer_acc IN SHARE MODE;
    -- Further SQL statements
COMMIT;

BEGIN;
    LOCK TABLE bank_customer IN SHARE MODE;
    LOCK TABLE customer_acc IN SHARE MODE;

    SELECT
        COUNT(*) / (SELECT COUNT(*) FROM bank_customer) AS avg_account_per_customer
    FROM 
        customer_acc;
COMMIT;

BEGIN;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    SELECT * FROM bank_customer;
END;

BEGIN;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    SELECT * FROM bank_customer;
END;


CREATE OR REPLACE PROCEDURE generate_retro_loom_data () 
LANGUAGE plpgsql AS $$
BEGIN
	-- Disable foreign key checks
	SET session_replication_role = 'replica';

	-- Truncate all tables to delete data and reset serial sequences
	TRUNCATE TABLE 
		complaint, invoice_item, invoice, delivery_item, delivery, order_item, 
		customer_order, product, product_cat, customer RESTART IDENTITY CASCADE;

	-- Re-enable foreign key checks
	SET session_replication_role = 'origin';

	-- Set up sequences for readability
	ALTER SEQUENCE customer_id_seq RESTART WITH 71;
	ALTER SEQUENCE customer_order_id_seq RESTART WITH 101;
	ALTER SEQUENCE delivery_id_seq RESTART WITH 301;
	ALTER SEQUENCE invoice_id_seq RESTART WITH 501;
	ALTER SEQUENCE complaint_id_seq RESTART WITH 901;

	-- Insert product categories
	INSERT INTO product_cat (id, name) VALUES
		('TOP', 'Tops'), ('BOT', 'Bottoms'), ('ACC', 'Accessories');

	-- Insert apparel products
	INSERT INTO product (id, name, category_id, gender, price, stock) VALUES
	-- Same price for rank demonstration
		('TEE', 'T-Shirt', 'TOP', 'U', 19.99, 100),  ('SHIR', 'Shirt', 'TOP', 'M', 35.00, 50),
		('BLZ', 'Blazer', 'TOP', 'M', 100.00, 25), ('JKT', 'Jacket', 'TOP', 'U', 100.00, 30),
		('PNT', 'Pants', 'BOT', 'M', 50.00, 60), ('SKT', 'Skirt', 'BOT', 'F', 45.00, 40),
		('BAG', 'Bag', 'ACC', 'U', 60.00, 70), ('BELT', 'Belt', 'ACC', 'U', 25.00, 120);

	-- Insert customers
	INSERT INTO customer (name, email, phone, mobile, address, is_active, referrer_id) VALUES
		('Alice Smith', 'alice@example.com', NULL, '555-1234', '123 Main St', TRUE, NULL),
		('Bob Johnson', 'bob@example.com', '555-5678', NULL, '456 Elm St', TRUE, NULL),
		('Charlie Brown', 'charlie@example.com', NULL, '555-4321', '789 Oak St', TRUE, 71),
		('Diana Prince', 'diana@example.com', '555-8765', NULL, '246 Pine St', TRUE, 71),
		('Eve Adams', 'eve@example.com', '555-9876', NULL, '135 Maple St', TRUE, NULL);
	
	-- Insert customer orders
	INSERT INTO customer_order (customer_id, order_ts, is_gift, custom_note, req_dlv_date) VALUES
		(71, NOW(), FALSE, ' Special gift for friend', NULL),
		(72, NOW(), TRUE, 'Urgent order', '2024-10-01'),
		(73, NOW(), FALSE, ' Thanks for your business', '2024-10-05'),
		(74, NOW(), FALSE, 'Order for special event', NULL), -- NULL req_dlv_date
		(75, NOW(), TRUE, ' Gift for a birthday', '2024-09-20'); -- Another order

	-- Insert order items
	INSERT INTO order_item (order_id, order_item_no, product_id, quantity, price, amount) VALUES
		(101, 1, 'TEE', 2, 18.99, 37.98), -- Price less than product price
		(101, 2, 'PNT', 1, 50.00, 50.00), -- Price equal to product price
		(102, 1, 'BLZ', 1, 105.00, 105.00), -- Price greater than product price
		(102, 2, 'BELT', 2, 25.00, 50.00), -- Price equal to product price
		(103, 1, 'SHIR', 3, 35.00, 105.00), -- Price equal to product price
		(103, 2, 'SKT', 1, 40.00, 40.00), -- Price less than product price
		(104, 1, 'BAG', 1, 60.00, 60.00), -- Price equal to product price
		(105, 1, 'JKT', 1, 100.00, 100.00); -- Price equal to product price

	-- Insert deliveries
	INSERT INTO delivery (delivery_ts, is_shipped, track_url, customer_id) VALUES
		(NOW(), FALSE, 'http://trackurl.com/1', 71), -- Pending delivery
		(NOW(), TRUE, 'http://trackurl.com/2', 72), -- Completed delivery
		(NOW(), FALSE, 'http://trackurl.com/3', 73), -- Pending delivery
		(NOW(), TRUE, 'http://trackurl.com/4', 74), -- Completed delivery
		(NOW(), TRUE, 'http://trackurl.com/5', 72); -- Another delivery for order 2

	-- Insert delivery items
	INSERT INTO delivery_item (delivery_id, delivery_item_no, order_id, order_item_no, dlv_quantity) VALUES
		(301, 1, 101, 1, 1), -- Partial delivery for order 101, item 1
		(302, 1, 102, 1, 1), -- Full delivery for order 102, item 1
		(302, 2, 102, 2, 2), -- Full delivery for order 102, item 2
		(303, 1, 103, 1, 3), -- Full delivery for order 103, item 1
		(304, 1, 103, 2, 1), -- Full delivery for order 103, item 2
		(305, 1, 102, 1, 1), -- Additional delivery for order 102, item 1
		(305, 2, 104, 1, 1); -- Delivery including item from order 104

	-- Insert invoices
	INSERT INTO invoice (invoice_ts, is_sent, customer_id) VALUES
		(NOW(), FALSE, 71), -- Pending invoice for customer 1
		(NOW(), TRUE, 72), -- Completed invoice for customer 2
		(NOW(), FALSE, 73), -- Pending invoice for customer 3
		(NOW(), TRUE, 74); -- Completed invoice for customer 4
	
	-- Insert invoice items
	INSERT INTO invoice_item (
		invoice_id, invoice_item_no, delivery_id, delivery_item_no, 
		amount, vat_rate, vat_amount, total_amount
	) VALUES
		(501, 1, 301, 1, 18.99, 20.00, 3.80, 22.79), -- Partial invoice for dlv 301, item 1
		(502, 1, 302, 1, 105.00, 20.00, 21.00, 126.00), -- Full invoice for dlv 302, item 1
		(502, 2, 302, 2, 50.00, 20.00, 10.00, 60.00), -- Full invoice for dlv 302, item 2
		(503, 1, 303, 1, 105.00, 20.00, 21.00, 126.00), -- Full invoice for dlv 303, item 1
		(504, 1, 304, 1, 40.00, 20.00, 8.00, 48.00); -- Full invoice for dlv 304, item 2

	-- Insert complaints
	INSERT INTO complaint(customer_id, order_id, complaint_ts, subject, description, is_resolved) VALUES
		(71, 101, NOW(), 'Website slow', 'I had to wait at submit', false), -- Order complaint
		(75, null, NOW(), 'No gift card', 'We want gift card option', false); -- Generic complaint
END;
$$
;
