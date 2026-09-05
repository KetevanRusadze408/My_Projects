--i applied dbeaver default formatter to all my scripts.
GRANT USAGE ON
SCHEMA bl_cl TO dwh_etl;

GRANT USAGE ON
SCHEMA bl_3nf TO dwh_etl;

GRANT
SELECT
	ON
	ALL TABLES IN SCHEMA bl_3nf TO dwh_etl;

GRANT USAGE ON
SCHEMA bl_dm TO dwh_etl;

GRANT
SELECT
	,
	INSERT
	,
	UPDATE
	,
	DELETE
	ON
	ALL TABLES IN SCHEMA bl_dm TO dwh_etl;

GRANT USAGE,
SELECT
	ON
	ALL SEQUENCES IN SCHEMA bl_dm TO dwh_etl;

ALTER DEFAULT PRIVILEGES IN SCHEMA bl_dm
GRANT
SELECT
	,
	INSERT
	,
	UPDATE
	,
	DELETE
	ON
	TABLES TO dwh_etl;

ALTER DEFAULT PRIVILEGES IN SCHEMA bl_dm
GRANT USAGE,
SELECT
	ON
	SEQUENCES TO dwh_etl;

DO $$
BEGIN
    IF NOT EXISTS
    (
SELECT
	1
FROM
	pg_type t
JOIN pg_namespace n ON
	n.oid = t.typnamespace
WHERE
	n.nspname = 'bl_cl'
	AND t.typname = 'hotel_type'
    ) THEN
        CREATE TYPE bl_cl.hotel_type AS
        (
            hotel_src_id VARCHAR(100),
            hotel_name VARCHAR(150),
            city_name VARCHAR(100),
            source_system VARCHAR(100),
            source_entity VARCHAR(100)
        );
END IF;

IF NOT EXISTS
    (
SELECT
	1
FROM
	pg_type t
JOIN pg_namespace n ON
	n.oid = t.typnamespace
WHERE
	n.nspname = 'bl_cl'
	AND t.typname = 'room_type'
    ) THEN
        CREATE TYPE bl_cl.room_type AS
        (
            room_src_id VARCHAR(500),
            reserved_room_type VARCHAR(50),
            assigned_room_type VARCHAR(50),
            product_bundle VARCHAR(100),
            source_system VARCHAR(100),
            source_entity VARCHAR(100)
        );
END IF;
END;

$$;

CREATE OR REPLACE
PROCEDURE bl_cl.load_dim_times()
LANGUAGE plpgsql
AS $$
DECLARE
    v_min_date DATE;

v_max_date DATE;

v_rows_affected BIGINT := 0;

BEGIN
    SELECT
	MIN(x.time_date),
	MAX(x.time_date)
    INTO
	v_min_date,
	v_max_date
FROM
	(
	SELECT
		TO_DATE(b.arrival_date_src_id, 'YYYY-FMMonth-DD') AS time_date
	FROM
		bl_3nf.ce_bookings b
	WHERE
		b.booking_id <> -1
		AND b.arrival_date_src_id ~ '^[0-9]{4}-[A-Za-z]+-[0-9]{1,2}$'
UNION ALL
	SELECT
		TO_DATE(b.reservation_status_date_src_id, 'YYYY-MM-DD')
	FROM
		bl_3nf.ce_bookings b
	WHERE
		b.booking_id <> -1
		AND b.reservation_status_date_src_id ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
    ) x;

v_min_date := COALESCE(v_min_date, DATE '2010-01-01');

v_max_date := COALESCE(v_max_date, DATE '2026-12-31');

INSERT
	INTO
	bl_dm.dim_times
    (
        time_actual,
	time_year,
	time_month,
	time_week_num,
	time_day_of_month,
	time_week_name,
	quarter_num,
	quarter_name,
	is_leap_year,
	insert_dt,
	update_dt
    )
    SELECT
	g.time_actual,
	EXTRACT(YEAR FROM g.time_actual)::INTEGER,
	EXTRACT(MONTH FROM g.time_actual)::INTEGER,
	EXTRACT(WEEK FROM g.time_actual)::INTEGER,
	EXTRACT(DAY FROM g.time_actual)::INTEGER,
	TRIM(TO_CHAR(g.time_actual, 'Day')),
	EXTRACT(QUARTER FROM g.time_actual)::INTEGER,
	'Q' || EXTRACT(QUARTER FROM g.time_actual)::INTEGER,
	CASE
		WHEN
            (
                EXTRACT(YEAR FROM g.time_actual)::INTEGER % 4 = 0
		AND EXTRACT(YEAR FROM g.time_actual)::INTEGER % 100 <> 0
            )
		OR EXTRACT(YEAR FROM g.time_actual)::INTEGER % 400 = 0
            THEN 1
		ELSE 0
	END,
	CURRENT_DATE,
	CURRENT_DATE
FROM
	(
	SELECT
		generate_series
        (
            v_min_date::TIMESTAMP,
		v_max_date::TIMESTAMP + INTERVAL '21 hours',
		INTERVAL '3 hours'
        ) AS time_actual
    ) g
    ON
	CONFLICT (time_actual) DO NOTHING;

GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

CALL bl_cl.insert_etl_log
    (
        'load_dim_times',
v_rows_affected,
'time dimension loaded successfully'
    );

EXCEPTION
WHEN OTHERS THEN
        CALL bl_cl.insert_etl_log
        (
            'load_dim_times',
0,
LEFT(SQLERRM, 1000),
'FAILED',
SQLSTATE
        );

RAISE;
END;

$$;

CREATE OR REPLACE
PROCEDURE bl_cl.load_dim_hotels()
LANGUAGE plpgsql
AS $$
DECLARE
    v_hotel bl_cl.hotel_type;

cur_hotels CURSOR FOR
        SELECT
	h.hotel_src_id,
	h.hotel_name,
	COALESCE(c.city_name, 'n. a.') AS city_name,
	h.source_system,
	h.source_entity
FROM
	bl_3nf.ce_hotels h
LEFT JOIN bl_3nf.ce_cities c ON
	c.city_id = h.city_id
WHERE
	h.hotel_id <> -1;

v_sql TEXT;

v_one_row BIGINT := 0;

v_rows_affected BIGINT := 0;

BEGIN
    v_sql := '
        INSERT INTO bl_dm.dim_hotels
        (
            hotel_src_id, hotel_name, city_name, star_rating,
            insert_dt, update_dt, source_entity, source_system
        )
        VALUES ($1, $2, $3, -1, CURRENT_DATE, CURRENT_DATE, $4, $5)
        ON CONFLICT (hotel_src_id, source_system, source_entity)
        DO UPDATE SET
            hotel_name = EXCLUDED.hotel_name,
            city_name = EXCLUDED.city_name,
            update_dt = CURRENT_DATE
        WHERE bl_dm.dim_hotels.hotel_name IS DISTINCT FROM EXCLUDED.hotel_name
           OR bl_dm.dim_hotels.city_name IS DISTINCT FROM EXCLUDED.city_name';

OPEN cur_hotels;

LOOP
        FETCH cur_hotels
INTO
	v_hotel;

EXIT
WHEN NOT FOUND;

EXECUTE v_sql
	USING
            v_hotel.hotel_src_id,
            v_hotel.hotel_name,
            v_hotel.city_name,
            v_hotel.source_entity,
            v_hotel.source_system;

GET DIAGNOSTICS v_one_row = ROW_COUNT;

v_rows_affected := v_rows_affected + v_one_row;
END LOOP;

CLOSE cur_hotels;

CALL bl_cl.insert_etl_log
    (
        'load_dim_hotels',
v_rows_affected,
'hotel dimension loaded successfully'
    );

EXCEPTION
WHEN OTHERS THEN
        /* The cursor portal is cleaned up when the failed statement ends. */
        CALL bl_cl.insert_etl_log
        (
            'load_dim_hotels',
0,
LEFT(SQLERRM, 1000),
'FAILED',
SQLSTATE
        );

RAISE;
END;

$$;

CREATE OR REPLACE
PROCEDURE bl_cl.load_dim_rooms()
LANGUAGE plpgsql
AS $$
DECLARE
    v_room bl_cl.room_type;

cur_rooms CURSOR FOR
        SELECT
	room_src_id,
	reserved_room_type,
	assigned_room_type,
	product_bundle,
	source_system,
	source_entity
FROM
	bl_3nf.ce_rooms
WHERE
	room_id <> -1;

v_sql TEXT;

v_one_row BIGINT := 0;

v_rows_affected BIGINT := 0;

BEGIN
    v_sql := '
        INSERT INTO bl_dm.dim_rooms
        (
            room_src_id, reserved_room_type, assigned_room_type,
            product_bundle, insert_dt, update_dt, source_entity, source_system
        )
        VALUES ($1, $2, $3, $4, CURRENT_DATE, CURRENT_DATE, $5, $6)
        ON CONFLICT (room_src_id, source_system, source_entity)
        DO UPDATE SET
            reserved_room_type = EXCLUDED.reserved_room_type,
            assigned_room_type = EXCLUDED.assigned_room_type,
            product_bundle = EXCLUDED.product_bundle,
            update_dt = CURRENT_DATE
        WHERE bl_dm.dim_rooms.reserved_room_type
                IS DISTINCT FROM EXCLUDED.reserved_room_type
           OR bl_dm.dim_rooms.assigned_room_type
                IS DISTINCT FROM EXCLUDED.assigned_room_type
           OR bl_dm.dim_rooms.product_bundle
                IS DISTINCT FROM EXCLUDED.product_bundle';

OPEN cur_rooms;

LOOP
        FETCH cur_rooms
INTO
	v_room;

EXIT
WHEN NOT FOUND;

EXECUTE v_sql
	USING
            v_room.room_src_id,
            v_room.reserved_room_type,
            v_room.assigned_room_type,
            v_room.product_bundle,
            v_room.source_entity,
            v_room.source_system;

GET DIAGNOSTICS v_one_row = ROW_COUNT;

v_rows_affected := v_rows_affected + v_one_row;
END LOOP;

CLOSE cur_rooms;

CALL bl_cl.insert_etl_log
    (
        'load_dim_rooms',
v_rows_affected,
'room dimension loaded successfully'
    );

EXCEPTION
WHEN OTHERS THEN
        CALL bl_cl.insert_etl_log
        (
            'load_dim_rooms',
0,
LEFT(SQLERRM, 1000),
'FAILED',
SQLSTATE
        );

RAISE;
END;

$$;

CREATE OR REPLACE
PROCEDURE bl_cl.load_dim_channels()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected BIGINT := 0;

BEGIN
    INSERT
	INTO
	bl_dm.dim_channels
    (
        market_segment,
	distribution_channel,
	insert_dt,
	update_dt,
	source_system,
	source_entity
    )
    SELECT
	DISTINCT
        market_segment,
	distribution_channel,
	CURRENT_DATE,
	CURRENT_DATE,
	source_system,
	source_entity
FROM
	bl_3nf.ce_booking_details
WHERE
	booking_details_id <> -1
    ON
	CONFLICT (market_segment,
	distribution_channel,
	source_system,
	source_entity)
    DO NOTHING;

GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

CALL bl_cl.insert_etl_log
    (
        'load_dim_channels',
v_rows_affected,
'channel dimension loaded successfully'
    );

EXCEPTION
WHEN OTHERS THEN
        CALL bl_cl.insert_etl_log
        (
            'load_dim_channels',
0,
LEFT(SQLERRM, 1000),
'FAILED',
SQLSTATE
        );

RAISE;
END;

$$;

CREATE OR REPLACE
PROCEDURE bl_cl.load_dim_reservation_statuses()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected BIGINT := 0;

BEGIN
    INSERT
	INTO
	bl_dm.dim_reservation_statuses
    (
        reservation_status,
	is_canceled,
	deposit_type,
	meal,
	adults,
	children,
	babies,
	required_car_parking_spaces,
	total_of_special_requests,
	insert_dt,
	update_dt,
	source_system,
	source_entity
    )
    SELECT
	DISTINCT
        reservation_status,
	is_canceled,
	deposit_type,
	meal,
	adults,
	children,
	babies,
	required_car_parking_spaces,
	total_of_special_requests,
	CURRENT_DATE,
	CURRENT_DATE,
	source_system,
	source_entity
FROM
	bl_3nf.ce_booking_details
WHERE
	booking_details_id <> -1
    ON
	CONFLICT
    (
        reservation_status,
	is_canceled,
	deposit_type,
	meal,
	adults,
	children,
	babies,
	required_car_parking_spaces,
	total_of_special_requests,
	source_system,
	source_entity
    )
    DO NOTHING;

GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

CALL bl_cl.insert_etl_log
    (
        'load_dim_reservation_statuses',
        v_rows_affected,
        'reservation status dimension loaded successfully'
    );

EXCEPTION
WHEN OTHERS THEN
        CALL bl_cl.insert_etl_log
        (
            'load_dim_reservation_statuses',
            0,
            LEFT(SQLERRM, 1000),
            'FAILED',
            SQLSTATE
        );

RAISE;
END;

$$;

CREATE OR REPLACE
PROCEDURE bl_cl.load_dim_customers()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected BIGINT := 0;

BEGIN
    INSERT
	INTO
	bl_dm.dim_customers AS dest
    (
        customer_src_id,
	customer_type,
	country_name,
	is_repeated_guest,
	previous_cancellations,
	previous_bookings_not_cancelled,
	company,
	agent,
	start_dt,
	end_dt,
	is_active,
	insert_dt,
	update_dt,
	source_system,
	source_entity
    )
    SELECT
	c.customer_src_id,
	c.customer_type,
	COALESCE(co.country_name, 'n. a.'),
	c.is_repeated_guest,
	c.previous_cancellations,
	c.previous_bookings_not_canceled,
	c.company,
	c.agent,
	c.start_dt,
	c.end_dt,
	c.is_active,
	c.insert_dt,
	c.update_dt,
	c.source_system,
	c.source_entity
FROM
	bl_3nf.ce_customers_scd c
LEFT JOIN bl_3nf.ce_countries co ON
	co.country_id = c.country_id
WHERE
	c.customer_id <> -1
    ON
	CONFLICT (customer_src_id,
	source_system,
	source_entity,
	start_dt)
    DO
UPDATE
SET
	customer_type = EXCLUDED.customer_type,
	country_name = EXCLUDED.country_name,
	is_repeated_guest = EXCLUDED.is_repeated_guest,
	previous_cancellations = EXCLUDED.previous_cancellations,
	previous_bookings_not_cancelled = EXCLUDED.previous_bookings_not_cancelled,
	company = EXCLUDED.company,
	agent = EXCLUDED.agent,
	end_dt = EXCLUDED.end_dt,
	is_active = EXCLUDED.is_active,
	update_dt = EXCLUDED.update_dt
WHERE
	dest.customer_type IS DISTINCT
FROM
	EXCLUDED.customer_type
	OR dest.country_name IS DISTINCT
FROM
	EXCLUDED.country_name
	OR dest.is_repeated_guest IS DISTINCT
FROM
	EXCLUDED.is_repeated_guest
	OR dest.previous_cancellations IS DISTINCT
FROM
	EXCLUDED.previous_cancellations
	OR dest.previous_bookings_not_cancelled
            IS DISTINCT
FROM
	EXCLUDED.previous_bookings_not_cancelled
	OR dest.company IS DISTINCT
FROM
	EXCLUDED.company
	OR dest.agent IS DISTINCT
FROM
	EXCLUDED.agent
	OR dest.end_dt IS DISTINCT
FROM
	EXCLUDED.end_dt
	OR dest.is_active IS DISTINCT
FROM
	EXCLUDED.is_active;

GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

CALL bl_cl.insert_etl_log
    (
        'load_dim_customers',
        v_rows_affected,
        'customer SCD Type 2 dimension loaded successfully'
    );

EXCEPTION
WHEN OTHERS THEN
        CALL bl_cl.insert_etl_log
        (
            'load_dim_customers',
0,
LEFT(SQLERRM, 1000),
'FAILED',
SQLSTATE
        );

RAISE;
END;

$$;

GRANT EXECUTE ON
PROCEDURE bl_cl.load_dim_times() TO dwh_etl;

GRANT EXECUTE ON
PROCEDURE bl_cl.load_dim_hotels() TO dwh_etl;

GRANT EXECUTE ON
PROCEDURE bl_cl.load_dim_rooms() TO dwh_etl;

GRANT EXECUTE ON
PROCEDURE bl_cl.load_dim_channels() TO dwh_etl;

GRANT EXECUTE ON
PROCEDURE bl_cl.load_dim_reservation_statuses() TO dwh_etl;

GRANT EXECUTE ON
PROCEDURE bl_cl.load_dim_customers() TO dwh_etl;
