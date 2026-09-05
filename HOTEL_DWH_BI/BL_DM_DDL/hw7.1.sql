--i applied dbeaver default formatter to all my scripts.
BEGIN;

CREATE SCHEMA IF NOT EXISTS bl_dm;

CREATE SEQUENCE IF NOT EXISTS bl_dm.seq_dim_times;

CREATE SEQUENCE IF NOT EXISTS bl_dm.seq_dim_hotels;

CREATE SEQUENCE IF NOT EXISTS bl_dm.seq_dim_rooms;

CREATE SEQUENCE IF NOT EXISTS bl_dm.seq_dim_customers;

CREATE SEQUENCE IF NOT EXISTS bl_dm.seq_dim_channels;

CREATE SEQUENCE IF NOT EXISTS bl_dm.seq_dim_statuses;

CREATE TABLE IF NOT EXISTS bl_dm.dim_times
(
    time_id BIGINT PRIMARY KEY DEFAULT nextval('bl_dm.seq_dim_times'),
    time_actual TIMESTAMP NOT NULL,
    time_year INTEGER NOT NULL,
    time_month INTEGER NOT NULL,
    time_week_num INTEGER NOT NULL,
    time_day_of_month INTEGER NOT NULL,
    time_week_name VARCHAR(20) NOT NULL,
    quarter_num INTEGER NOT NULL,
    quarter_name VARCHAR(5) NOT NULL,
    is_leap_year INTEGER NOT NULL,
    insert_dt DATE NOT NULL,
    update_dt DATE NOT NULL,
    CONSTRAINT uq_dim_times_actual UNIQUE (time_actual)
);

CREATE TABLE IF NOT EXISTS bl_dm.dim_hotels
(
    hotel_surr_id BIGINT PRIMARY KEY DEFAULT nextval('bl_dm.seq_dim_hotels'),
    hotel_src_id VARCHAR(100) NOT NULL,
    hotel_name VARCHAR(150) NOT NULL,
    city_name VARCHAR(100) NOT NULL,
    star_rating INTEGER NOT NULL DEFAULT -1,
    insert_dt DATE NOT NULL,
    update_dt DATE NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    source_system VARCHAR(100) NOT NULL,
    CONSTRAINT uq_dim_hotels_source
        UNIQUE (hotel_src_id,
source_system,
source_entity)
);

CREATE TABLE IF NOT EXISTS bl_dm.dim_rooms
(
    room_surr_id BIGINT PRIMARY KEY DEFAULT nextval('bl_dm.seq_dim_rooms'),
    room_src_id VARCHAR(500) NOT NULL,
    reserved_room_type VARCHAR(50) NOT NULL,
    assigned_room_type VARCHAR(50) NOT NULL,
    product_bundle VARCHAR(100) NOT NULL,
    insert_dt DATE NOT NULL,
    update_dt DATE NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    source_system VARCHAR(100) NOT NULL,
    CONSTRAINT uq_dim_rooms_source
        UNIQUE (room_src_id,
source_system,
source_entity)
);

CREATE TABLE IF NOT EXISTS bl_dm.dim_customers
(
    customer_surr_id BIGINT PRIMARY KEY DEFAULT nextval('bl_dm.seq_dim_customers'),
    customer_src_id VARCHAR(100) NOT NULL,
    customer_type VARCHAR(100) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    is_repeated_guest INTEGER NOT NULL,
    previous_cancellations INTEGER NOT NULL,
    previous_bookings_not_cancelled INTEGER NOT NULL,
    company VARCHAR(100) NOT NULL,
    agent VARCHAR(100) NOT NULL,
    start_dt TIMESTAMP NOT NULL,
    end_dt TIMESTAMP NOT NULL,
    is_active VARCHAR(1) NOT NULL,
    insert_dt DATE NOT NULL,
    update_dt DATE NOT NULL,
    source_system VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    CONSTRAINT uq_dim_customers_source
        UNIQUE (customer_src_id,
source_system,
source_entity,
start_dt)
);

CREATE TABLE IF NOT EXISTS bl_dm.dim_channels
(
    channel_surr_id BIGINT PRIMARY KEY DEFAULT nextval('bl_dm.seq_dim_channels'),
    market_segment VARCHAR(100) NOT NULL,
    distribution_channel VARCHAR(100) NOT NULL,
    insert_dt DATE NOT NULL,
    update_dt DATE NOT NULL,
    source_system VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    CONSTRAINT uq_dim_channels_source
        UNIQUE (market_segment,
distribution_channel,
source_system,
source_entity)
);

CREATE TABLE IF NOT EXISTS bl_dm.dim_reservation_statuses
(
    status_surr_id BIGINT PRIMARY KEY DEFAULT nextval('bl_dm.seq_dim_statuses'),
    reservation_status VARCHAR(100) NOT NULL,
    is_canceled INTEGER NOT NULL,
    deposit_type VARCHAR(100) NOT NULL,
    meal VARCHAR(100) NOT NULL,
    adults INTEGER NOT NULL,
    children INTEGER NOT NULL,
    babies INTEGER NOT NULL,
    required_car_parking_spaces INTEGER NOT NULL,
    total_of_special_requests INTEGER NOT NULL,
    insert_dt DATE NOT NULL,
    update_dt DATE NOT NULL,
    source_system VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    CONSTRAINT uq_dim_status_source
        UNIQUE
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
);

COMMIT;

BEGIN;

INSERT
	INTO
	bl_dm.dim_times
(
    time_id,
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
VALUES
(
    -1,
TIMESTAMP '1900-01-01 00:00:00',
-1,
-1,
-1,
    -1,
'n. a.',
-1,
'n. a.',
-1,
DATE '1900-01-01',
DATE '1900-01-01'
)
ON
CONFLICT DO NOTHING;

INSERT
	INTO
	bl_dm.dim_hotels
(
    hotel_surr_id,
	hotel_src_id,
	hotel_name,
	city_name,
	star_rating,
	insert_dt,
	update_dt,
	source_entity,
	source_system
)
VALUES
(
    -1,
'n. a.',
'n. a.',
'n. a.',
-1,
    DATE '1900-01-01',
DATE '1900-01-01',
'DEFAULT',
'DEFAULT'
)
ON
CONFLICT DO NOTHING;

INSERT
	INTO
	bl_dm.dim_rooms
(
    room_surr_id,
	room_src_id,
	reserved_room_type,
	assigned_room_type,
	product_bundle,
	insert_dt,
	update_dt,
	source_entity,
	source_system
)
VALUES
(
    -1,
'n. a.',
'n. a.',
'n. a.',
'n. a.',
    DATE '1900-01-01',
DATE '1900-01-01',
'DEFAULT',
'DEFAULT'
)
ON
CONFLICT DO NOTHING;

INSERT
	INTO
	bl_dm.dim_customers
(
    customer_surr_id,
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
VALUES
(
    -1,
'n. a.',
'n. a.',
'n. a.',
-1,
-1,
-1,
'n. a.',
'n. a.',
    DATE '1900-01-01',
DATE '9999-12-31',
'Y',
    DATE '1900-01-01',
DATE '1900-01-01',
'DEFAULT',
'DEFAULT'
)
ON
CONFLICT DO NOTHING;

INSERT
	INTO
	bl_dm.dim_channels
(
    channel_surr_id,
	market_segment,
	distribution_channel,
	insert_dt,
	update_dt,
	source_system,
	source_entity
)
VALUES
(
    -1,
'n. a.',
'n. a.',
DATE '1900-01-01',
DATE '1900-01-01',
    'DEFAULT',
'DEFAULT'
)
ON
CONFLICT DO NOTHING;

INSERT
	INTO
	bl_dm.dim_reservation_statuses
(
    status_surr_id,
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
VALUES
(
    -1,
'n. a.',
-1,
'n. a.',
'n. a.',
-1,
-1,
-1,
-1,
-1,
    DATE '1900-01-01',
DATE '1900-01-01',
'DEFAULT',
'DEFAULT'
)
ON
CONFLICT DO NOTHING;

COMMIT;

SELECT
	'dim_times' AS table_name,
	COUNT(*) AS row_count
FROM
	bl_dm.dim_times
UNION ALL
SELECT
	'dim_hotels',
	COUNT(*)
FROM
	bl_dm.dim_hotels
UNION ALL
SELECT
	'dim_rooms',
	COUNT(*)
FROM
	bl_dm.dim_rooms
UNION ALL
SELECT
	'dim_customers',
	COUNT(*)
FROM
	bl_dm.dim_customers
UNION ALL
SELECT
	'dim_channels',
	COUNT(*)
FROM
	bl_dm.dim_channels
UNION ALL
SELECT
	'dim_reservation_statuses',
	COUNT(*)
FROM
	bl_dm.dim_reservation_statuses
ORDER BY
	table_name;
