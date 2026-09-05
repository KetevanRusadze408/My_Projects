--i applied dbeaver default formatter to all my scripts to make it more readable
BEGIN;

CREATE EXTENSION IF NOT EXISTS file_fdw;

CREATE SERVER IF NOT EXISTS file_server FOREIGN DATA WRAPPER file_fdw;

CREATE SCHEMA IF NOT EXISTS sa_city_hotel;

CREATE SCHEMA IF NOT EXISTS sa_resort_hotel;

CREATE SCHEMA IF NOT EXISTS bl_cl;

CREATE TABLE IF NOT EXISTS bl_cl.etl_log
(
    log_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
log_dt TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
procedure_name VARCHAR(200) NOT NULL,
rows_affected BIGINT NOT NULL DEFAULT 0,
message VARCHAR(1000) NOT NULL,
status VARCHAR(20) NOT NULL DEFAULT 'SUCCESS',
error_code VARCHAR(20)
);

CREATE OR REPLACE
PROCEDURE bl_cl.insert_etl_log
(
    p_procedure_name VARCHAR(200),
p_rows_affected BIGINT,
p_message VARCHAR(1000),
p_status VARCHAR(20) DEFAULT 'SUCCESS',
p_error_code VARCHAR(20) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT
	INTO
	bl_cl.etl_log
    (
        procedure_name,
	rows_affected,
	message,
	status,
	error_code
    )
VALUES
    (
        p_procedure_name,
COALESCE(p_rows_affected, 0),
COALESCE(p_message, 'n. a.'),
COALESCE(p_status, 'SUCCESS'),
p_error_code
    );
END;

$$;

DROP FOREIGN TABLE IF EXISTS sa_city_hotel.ext_city_hotel;

CREATE FOREIGN TABLE sa_city_hotel.ext_city_hotel
(
    booking_id TEXT,
adr TEXT,
adults TEXT,
agent TEXT,
arrival_date_day_of_month TEXT,
arrival_date_month TEXT,
arrival_date_week_number TEXT,
arrival_date_year TEXT,
assigned_room_type TEXT,
babies TEXT,
booking_changes TEXT,
booking_src_id TEXT,
children TEXT,
company TEXT,
cost_amount TEXT,
country TEXT,
customer_src_id TEXT,
customer_type TEXT,
days_in_waiting_list TEXT,
deposit_type TEXT,
distribution_channel TEXT,
hotel TEXT,
is_canceled TEXT,
is_repeated_guest TEXT,
lead_time TEXT,
market_segment TEXT,
meal TEXT,
previous_bookings_not_canceled TEXT,
previous_cancellations TEXT,
product_bundle_name TEXT,
profit_amount TEXT,
required_car_parking_spaces TEXT,
reservation_status TEXT,
reservation_status_date TEXT,
reserved_room_type TEXT,
sales_amount TEXT,
source_system TEXT,
source_table TEXT,
stays_in_week_nights TEXT,
stays_in_weekend_nights TEXT,
total_of_special_requests TEXT,
total_nights TEXT,
city_name TEXT,
country_name TEXT,
hotel_key TEXT,
hotel_src_id TEXT,
hotel_name TEXT,
star_rating TEXT
)
SERVER file_server
OPTIONS
(
    filename 'C:/Users/User/Desktop/fin_presentation/presentation_csv/city_hotel_initial_95.csv',
format 'csv',
HEADER 'true',
DELIMITER ',',
QUOTE '"',
NULL ''
);

DROP FOREIGN TABLE IF EXISTS sa_resort_hotel.ext_resort_hotel;

CREATE FOREIGN TABLE sa_resort_hotel.ext_resort_hotel
(
    booking_id TEXT,
adr TEXT,
adults TEXT,
agent TEXT,
arrival_date_day_of_month TEXT,
arrival_date_month TEXT,
arrival_date_week_number TEXT,
arrival_date_year TEXT,
assigned_room_type TEXT,
babies TEXT,
booking_changes TEXT,
booking_src_id TEXT,
children TEXT,
company TEXT,
cost_amount TEXT,
country TEXT,
customer_src_id TEXT,
customer_type TEXT,
days_in_waiting_list TEXT,
deposit_type TEXT,
distribution_channel TEXT,
hotel TEXT,
is_canceled TEXT,
is_repeated_guest TEXT,
lead_time TEXT,
market_segment TEXT,
meal TEXT,
previous_bookings_not_canceled TEXT,
previous_cancellations TEXT,
product_bundle_name TEXT,
profit_amount TEXT,
required_car_parking_spaces TEXT,
reservation_status TEXT,
reservation_status_date TEXT,
reserved_room_type TEXT,
sales_amount TEXT,
source_system TEXT,
source_table TEXT,
stays_in_week_nights TEXT,
stays_in_weekend_nights TEXT,
total_of_special_requests TEXT,
total_nights TEXT,
city_name TEXT,
country_name TEXT,
hotel_key TEXT,
hotel_src_id TEXT,
hotel_name TEXT,
star_rating TEXT
)
SERVER file_server
OPTIONS
(
    filename 'C:/Users/User/Desktop/fin_presentation/presentation_csv/resort_hotel_initial_95.csv',
format 'csv',
HEADER 'true',
DELIMITER ',',
QUOTE '"',
NULL ''
);

CREATE TABLE IF NOT EXISTS sa_city_hotel.src_city_hotel
(
    booking_id TEXT,
adr TEXT,
adults TEXT,
agent TEXT,
arrival_date_day_of_month TEXT,
arrival_date_month TEXT,
arrival_date_week_number TEXT,
arrival_date_year TEXT,
assigned_room_type TEXT,
babies TEXT,
booking_changes TEXT,
booking_src_id TEXT,
children TEXT,
company TEXT,
cost_amount TEXT,
country TEXT,
customer_src_id TEXT,
customer_type TEXT,
days_in_waiting_list TEXT,
deposit_type TEXT,
distribution_channel TEXT,
hotel TEXT,
is_canceled TEXT,
is_repeated_guest TEXT,
lead_time TEXT,
market_segment TEXT,
meal TEXT,
previous_bookings_not_canceled TEXT,
previous_cancellations TEXT,
product_bundle_name TEXT,
profit_amount TEXT,
required_car_parking_spaces TEXT,
reservation_status TEXT,
reservation_status_date TEXT,
reserved_room_type TEXT,
sales_amount TEXT,
source_system TEXT,
source_table TEXT,
stays_in_week_nights TEXT,
stays_in_weekend_nights TEXT,
total_of_special_requests TEXT,
total_nights TEXT,
city_name TEXT,
country_name TEXT,
hotel_key TEXT,
hotel_src_id TEXT,
hotel_name TEXT,
star_rating TEXT,
load_dts TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
source_file_name TEXT NOT NULL DEFAULT 'n. a.'
);

CREATE TABLE IF NOT EXISTS sa_resort_hotel.src_resort_hotel
(
    booking_id TEXT,
adr TEXT,
adults TEXT,
agent TEXT,
arrival_date_day_of_month TEXT,
arrival_date_month TEXT,
arrival_date_week_number TEXT,
arrival_date_year TEXT,
assigned_room_type TEXT,
babies TEXT,
booking_changes TEXT,
booking_src_id TEXT,
children TEXT,
company TEXT,
cost_amount TEXT,
country TEXT,
customer_src_id TEXT,
customer_type TEXT,
days_in_waiting_list TEXT,
deposit_type TEXT,
distribution_channel TEXT,
hotel TEXT,
is_canceled TEXT,
is_repeated_guest TEXT,
lead_time TEXT,
market_segment TEXT,
meal TEXT,
previous_bookings_not_canceled TEXT,
previous_cancellations TEXT,
product_bundle_name TEXT,
profit_amount TEXT,
required_car_parking_spaces TEXT,
reservation_status TEXT,
reservation_status_date TEXT,
reserved_room_type TEXT,
sales_amount TEXT,
source_system TEXT,
source_table TEXT,
stays_in_week_nights TEXT,
stays_in_weekend_nights TEXT,
total_of_special_requests TEXT,
total_nights TEXT,
city_name TEXT,
country_name TEXT,
hotel_key TEXT,
hotel_src_id TEXT,
hotel_name TEXT,
star_rating TEXT,
load_dts TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
source_file_name TEXT NOT NULL DEFAULT 'n. a.'
);

COMMIT;

CREATE OR REPLACE PROCEDURE bl_cl.load_master_etl(
    p_city_csv_path VARCHAR DEFAULT NULL,
    p_resort_csv_path VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_city_staging_rows BIGINT := 0;
    v_resort_staging_rows BIGINT := 0;
BEGIN
    IF p_city_csv_path IS NOT NULL THEN
        EXECUTE format('ALTER FOREIGN TABLE sa_city_hotel.ext_city_hotel OPTIONS (SET filename %L)', p_city_csv_path);
    END IF;

    IF p_resort_csv_path IS NOT NULL THEN
        EXECUTE format('ALTER FOREIGN TABLE sa_resort_hotel.ext_resort_hotel OPTIONS (SET filename %L)', p_resort_csv_path);
    END IF;
    MERGE INTO sa_city_hotel.src_city_hotel AS target
    USING sa_city_hotel.ext_city_hotel AS ext
    ON target.booking_id = ext.booking_id
    WHEN MATCHED THEN
        UPDATE SET
            hotel = ext.hotel,
            is_canceled = ext.is_canceled,
            lead_time = ext.lead_time,
            arrival_date_year = ext.arrival_date_year,
            arrival_date_month = ext.arrival_date_month,
            arrival_date_week_number = ext.arrival_date_week_number,
            arrival_date_day_of_month = ext.arrival_date_day_of_month,
            stays_in_weekend_nights = ext.stays_in_weekend_nights,
            stays_in_week_nights = ext.stays_in_week_nights,
            adults = ext.adults,
            children = ext.children,
            babies = ext.babies,
            meal = ext.meal,
            country = ext.country,
            market_segment = ext.market_segment,
            distribution_channel = ext.distribution_channel,
            is_repeated_guest = ext.is_repeated_guest,
            previous_cancellations = ext.previous_cancellations,
            previous_bookings_not_canceled = ext.previous_bookings_not_canceled,
            reserved_room_type = ext.reserved_room_type,
            assigned_room_type = ext.assigned_room_type,
            booking_changes = ext.booking_changes,
            deposit_type = ext.deposit_type,
            agent = ext.agent,
            company = ext.company,
            days_in_waiting_list = ext.days_in_waiting_list,
            customer_type = ext.customer_type,
            adr = ext.adr,
            required_car_parking_spaces = ext.required_car_parking_spaces,
            total_of_special_requests = ext.total_of_special_requests,
            reservation_status = ext.reservation_status,
            reservation_status_date = ext.reservation_status_date,
            customer_src_id = ext.customer_src_id,
            cost_amount = ext.cost_amount,
            profit_amount = ext.profit_amount,
            sales_amount = ext.sales_amount,
            product_bundle_name = ext.product_bundle_name,
            source_system = ext.source_system,
            source_table = ext.source_table,
            total_nights = ext.total_nights,
            city_name = ext.city_name,
            country_name = ext.country_name,
            hotel_key = ext.hotel_key,
            hotel_src_id = ext.hotel_src_id,
            hotel_name = ext.hotel_name,
            star_rating = ext.star_rating,
            load_dts = clock_timestamp(),
            source_file_name = 'ext_city_hotel'
    WHEN NOT MATCHED THEN
        INSERT (
            booking_id, adr, adults, agent,
            arrival_date_day_of_month, arrival_date_month,
            arrival_date_week_number, arrival_date_year,
            assigned_room_type, babies, booking_changes, booking_src_id,
            children, company, cost_amount, country, customer_src_id,
            customer_type, days_in_waiting_list, deposit_type,
            distribution_channel, hotel, is_canceled, is_repeated_guest,
            lead_time, market_segment, meal,
            previous_bookings_not_canceled, previous_cancellations,
            product_bundle_name, profit_amount,
            required_car_parking_spaces, reservation_status,
            reservation_status_date, reserved_room_type, sales_amount,
            source_system, source_table, stays_in_week_nights,
            stays_in_weekend_nights, total_of_special_requests,
            total_nights, city_name, country_name, hotel_key,
            hotel_src_id, hotel_name, star_rating,
            load_dts, source_file_name
        )
        VALUES (
            ext.booking_id, ext.adr, ext.adults, ext.agent,
            ext.arrival_date_day_of_month, ext.arrival_date_month,
            ext.arrival_date_week_number, ext.arrival_date_year,
            ext.assigned_room_type, ext.babies, ext.booking_changes, ext.booking_src_id,
            ext.children, ext.company, ext.cost_amount, ext.country, ext.customer_src_id,
            ext.customer_type, ext.days_in_waiting_list, ext.deposit_type,
            ext.distribution_channel, ext.hotel, ext.is_canceled, ext.is_repeated_guest,
            ext.lead_time, ext.market_segment, ext.meal,
            ext.previous_bookings_not_canceled, ext.previous_cancellations,
            ext.product_bundle_name, ext.profit_amount,
            ext.required_car_parking_spaces, ext.reservation_status,
            ext.reservation_status_date, ext.reserved_room_type, ext.sales_amount,
            ext.source_system, ext.source_table, ext.stays_in_week_nights,
            ext.stays_in_weekend_nights, ext.total_of_special_requests,
            ext.total_nights, ext.city_name, ext.country_name, ext.hotel_key,
            ext.hotel_src_id, ext.hotel_name, ext.star_rating,
            clock_timestamp(), 'ext_city_hotel'
        );
    
    GET DIAGNOSTICS v_city_staging_rows = ROW_COUNT;

    MERGE INTO sa_resort_hotel.src_resort_hotel AS target
    USING sa_resort_hotel.ext_resort_hotel AS ext
    ON target.booking_id = ext.booking_id
    WHEN MATCHED THEN
        UPDATE SET
            hotel = ext.hotel,
            is_canceled = ext.is_canceled,
            lead_time = ext.lead_time,
            arrival_date_year = ext.arrival_date_year,
            arrival_date_month = ext.arrival_date_month,
            arrival_date_week_number = ext.arrival_date_week_number,
            arrival_date_day_of_month = ext.arrival_date_day_of_month,
            stays_in_weekend_nights = ext.stays_in_weekend_nights,
            stays_in_week_nights = ext.stays_in_week_nights,
            adults = ext.adults,
            children = ext.children,
            babies = ext.babies,
            meal = ext.meal,
            country = ext.country,
            market_segment = ext.market_segment,
            distribution_channel = ext.distribution_channel,
            is_repeated_guest = ext.is_repeated_guest,
            previous_cancellations = ext.previous_cancellations,
            previous_bookings_not_canceled = ext.previous_bookings_not_canceled,
            reserved_room_type = ext.reserved_room_type,
            assigned_room_type = ext.assigned_room_type,
            booking_changes = ext.booking_changes,
            deposit_type = ext.deposit_type,
            agent = ext.agent,
            company = ext.company,
            days_in_waiting_list = ext.days_in_waiting_list,
            customer_type = ext.customer_type,
            adr = ext.adr,
            required_car_parking_spaces = ext.required_car_parking_spaces,
            total_of_special_requests = ext.total_of_special_requests,
            reservation_status = ext.reservation_status,
            reservation_status_date = ext.reservation_status_date,
            customer_src_id = ext.customer_src_id,
            cost_amount = ext.cost_amount,
            profit_amount = ext.profit_amount,
            sales_amount = ext.sales_amount,
            product_bundle_name = ext.product_bundle_name,
            source_system = ext.source_system,
            source_table = ext.source_table,
            total_nights = ext.total_nights,
            city_name = ext.city_name,
            country_name = ext.country_name,
            hotel_key = ext.hotel_key,
            hotel_src_id = ext.hotel_src_id,
            hotel_name = ext.hotel_name,
            star_rating = ext.star_rating,
            load_dts = clock_timestamp(),
            source_file_name = 'ext_resort_hotel'
    WHEN NOT MATCHED THEN
        INSERT (
            booking_id, adr, adults, agent,
            arrival_date_day_of_month, arrival_date_month,
            arrival_date_week_number, arrival_date_year,
            assigned_room_type, babies, booking_changes, booking_src_id,
            children, company, cost_amount, country, customer_src_id,
            customer_type, days_in_waiting_list, deposit_type,
            distribution_channel, hotel, is_canceled, is_repeated_guest,
            lead_time, market_segment, meal,
            previous_bookings_not_canceled, previous_cancellations,
            product_bundle_name, profit_amount,
            required_car_parking_spaces, reservation_status,
            reservation_status_date, reserved_room_type, sales_amount,
            source_system, source_table, stays_in_week_nights,
            stays_in_weekend_nights, total_of_special_requests,
            total_nights, city_name, country_name, hotel_key,
            hotel_src_id, hotel_name, star_rating,
            load_dts, source_file_name
        )
        VALUES (
            ext.booking_id, ext.adr, ext.adults, ext.agent,
            ext.arrival_date_day_of_month, ext.arrival_date_month,
            ext.arrival_date_week_number, ext.arrival_date_year,
            ext.assigned_room_type, ext.babies, ext.booking_changes, ext.booking_src_id,
            ext.children, ext.company, ext.cost_amount, ext.country, ext.customer_src_id,
            ext.customer_type, ext.days_in_waiting_list, ext.deposit_type,
            ext.distribution_channel, ext.hotel, ext.is_canceled, ext.is_repeated_guest,
            ext.lead_time, ext.market_segment, ext.meal,
            ext.previous_bookings_not_canceled, ext.previous_cancellations,
            ext.product_bundle_name, ext.profit_amount,
            ext.required_car_parking_spaces, ext.reservation_status,
            ext.reservation_status_date, ext.reserved_room_type, ext.sales_amount,
            ext.source_system, ext.source_table, ext.stays_in_week_nights,
            ext.stays_in_weekend_nights, ext.total_of_special_requests,
            ext.total_nights, ext.city_name, ext.country_name, ext.hotel_key,
            ext.hotel_src_id, ext.hotel_name, ext.star_rating,
            clock_timestamp(), 'ext_resort_hotel'
        );

    GET DIAGNOSTICS v_resort_staging_rows = ROW_COUNT;
    CALL bl_cl.insert_etl_log(
        'load_master_etl_staging', 
        v_city_staging_rows + v_resort_staging_rows, 
        format('Staging loaded/updated via MERGE. city_rows=%s, resort_rows=%s', v_city_staging_rows, v_resort_staging_rows)
    );

    CALL bl_cl.load_ce_countries();
    CALL bl_cl.load_ce_cities();
    CALL bl_cl.load_ce_hotels();
    CALL bl_cl.load_ce_rooms();
    CALL bl_cl.load_ce_booking_details();
    CALL bl_cl.load_ce_customers_scd(); 
    CALL bl_cl.load_ce_bookings();
    CALL bl_cl.load_dim_times();
    CALL bl_cl.load_dim_hotels();
    CALL bl_cl.load_dim_rooms();
    CALL bl_cl.load_dim_channels();
    CALL bl_cl.load_dim_reservation_statuses();
    CALL bl_cl.load_dim_customers(); 
    CALL bl_cl.load_fct_bookings_dm();
    CALL bl_cl.insert_etl_log(
        'load_master_etl', 
        0, 
        'Master ETL Pipeline executed successfully.'
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.insert_etl_log('load_master_etl', 0, LEFT(SQLERRM, 1000), 'FAILED', SQLSTATE);
        RAISE;
END;
$$;

