
CREATE OR REPLACE FUNCTION check_category_c_return () RETURNS TRIGGER AS $$
BEGIN
	IF NEW.category = 'C' AND NEW.is_returned = TRUE THEN
		RAISE EXCEPTION 'Cannot return a ticket with category C';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION return_cancelled_tickets () RETURNS TRIGGER AS $$
	BEGIN
		IF NEW.is_cancelled = TRUE THEN
			UPDATE ticket_sale_item
				SET is_returned = TRUE
			WHERE
				event_id = NEW.id AND category <> 'C';
		END IF;

		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insert_event_and_theater () RETURNS TRIGGER AS $$
	BEGIN
		IF NOT EXISTS (SELECT id FROM theater WHERE id = NEW.theater_id) THEN
			INSERT INTO theater(id, name, capacity)
				VALUES (NEW.theater_id, NEW.theater_name, NEW.theater_capacity);
		END IF;
		
		INSERT INTO event(name, gig_ts, theater_id, artist_id, is_cancelled)
			VALUES (NEW.event_name, NEW.gig_ts, NEW.theater_id, NEW.artist_id, NEW.is_cancelled);

		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_products() 
RETURNS TIMESTAMP AS $serving$
BEGIN
	-- a. Add a column to the products_new table called last_update_date, 
	-- and populate the column with current date.
	ALTER TABLE products_new 
		ADD COLUMN last_update_date DATE;

	UPDATE products_new
		SET last_update_date = CURRENT_DATE;
	-- b. Remove products that have been discontinued (having a non NULL 
	-- production_end_date) and have a production_start_date earlier than 2020

	DELETE FROM products_new
		WHERE EXTRACT(YEAR FROM production_start_date) < 2020 AND production_end_date IS NOT NULL;
	-- c. If the production_end_date column is NULL, replace with the date 2999-01-01. 

	UPDATE products_new
		SET production_end_date = '2999-01-01' WHERE production_end_date IS NULL;
	-- 
	RETURN CURRENT_TIMESTAMP;
END; 
$serving$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION analyze_nulls(
    IN p_table_name text, 
    IN p_column_name text,
    OUT o_null_count integer,     -- Output 1: The quantity
    OUT o_null_percent numeric    -- Output 2: The percentage (e.g. 25.5)
) 
AS $$
DECLARE
    v_query text;
BEGIN
    -- Construct the query dynamically
    -- 1. count(*) FILTER (...) is a fast way to count only specific rows
    -- 2. NULLIF(count(*), 0) prevents division by zero error if table is empty
    v_query := format(
        'SELECT 
            count(*) FILTER (WHERE %I IS NULL),
            (count(*) FILTER (WHERE %I IS NULL)::numeric / NULLIF(count(*), 0)::numeric) * 100
         FROM %I',
        p_column_name, -- 1st %I (for the count)
        p_column_name, -- 2nd %I (for the math)
        p_table_name   -- 3rd %I (for the FROM clause)
    );

    -- Execute and store the results into the two OUT variables
    EXECUTE v_query INTO o_null_count, o_null_percent;
    
    -- Handle case where table is empty (result will be NULL)
    IF o_null_percent IS NULL THEN
        o_null_percent := 0;
    END IF;
    
    -- Optional: Round the percentage to 2 decimal places
    o_null_percent := round(o_null_percent, 2);
    
END;
$$ LANGUAGE plpgsql;


