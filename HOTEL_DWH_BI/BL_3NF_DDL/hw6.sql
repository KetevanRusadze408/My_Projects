DROP SCHEMA IF EXISTS bl_3nf CASCADE;
BEGIN;

CREATE SCHEMA bl_3nf;

--i applied dbeaver default formatter to all my scripts.
CREATE SEQUENCE bl_3nf.seq_country_id START WITH 1;
CREATE SEQUENCE bl_3nf.seq_city_id START WITH 1;
CREATE SEQUENCE bl_3nf.seq_hotel_id START WITH 1;
CREATE SEQUENCE bl_3nf.seq_room_id START WITH 1;
CREATE SEQUENCE bl_3nf.seq_booking_details_id START WITH 1;
CREATE SEQUENCE bl_3nf.seq_customer_id START WITH 1;
CREATE SEQUENCE bl_3nf.seq_booking_id START WITH 1;

CREATE TABLE bl_3nf.ce_countries
(
    country_id BIGINT DEFAULT nextval('bl_3nf.seq_country_id'),
    country_src_id VARCHAR(50) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    insert_dt DATE NOT NULL,
    update_dt DATE NOT NULL,
    source_system VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    CONSTRAINT pk_ce_countries PRIMARY KEY(country_id),
    CONSTRAINT uq_ce_countries_source UNIQUE(country_src_id, source_system, source_entity)
);

CREATE TABLE bl_3nf.ce_cities
(
    city_id BIGINT DEFAULT nextval('bl_3nf.seq_city_id'),
    city_src_id VARCHAR(100) NOT NULL,
    city_name VARCHAR(100) NOT NULL,
    country_id BIGINT NOT NULL,
    insert_dt DATE NOT NULL,
    update_dt DATE NOT NULL,
    source_system VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    CONSTRAINT pk_ce_cities PRIMARY KEY(city_id),
    CONSTRAINT uq_ce_cities_source UNIQUE(city_src_id, source_system, source_entity),
    CONSTRAINT fk_city_country FOREIGN KEY(country_id) REFERENCES bl_3nf.ce_countries(country_id)
);

CREATE TABLE bl_3nf.ce_hotels
(
    hotel_id BIGINT DEFAULT nextval('bl_3nf.seq_hotel_id'),
    hotel_src_id VARCHAR(100) NOT NULL,
    hotel_name VARCHAR(150) NOT NULL,
    city_id BIGINT NOT NULL,
    insert_dt DATE NOT NULL,
    update_dt DATE NOT NULL,
    source_system VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    CONSTRAINT pk_ce_hotels PRIMARY KEY(hotel_id),
    CONSTRAINT uq_ce_hotels_source UNIQUE(hotel_src_id, source_system, source_entity),
    CONSTRAINT fk_hotel_city FOREIGN KEY(city_id) REFERENCES bl_3nf.ce_cities(city_id)
);

CREATE TABLE bl_3nf.ce_rooms
(
    room_id BIGINT DEFAULT nextval('bl_3nf.seq_room_id'),
    room_src_id VARCHAR(500) NOT NULL,
    hotel_id BIGINT NOT NULL,
    reserved_room_type VARCHAR(50) NOT NULL,
    assigned_room_type VARCHAR(50) NOT NULL,
    product_bundle VARCHAR(100) NOT NULL,
    insert_dt DATE NOT NULL,
    update_dt DATE NOT NULL,
    source_system VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    CONSTRAINT pk_ce_rooms PRIMARY KEY(room_id),
    CONSTRAINT uq_ce_rooms_source UNIQUE(room_src_id, source_system, source_entity),
    CONSTRAINT fk_room_hotel FOREIGN KEY(hotel_id) REFERENCES bl_3nf.ce_hotels(hotel_id)
);

CREATE TABLE bl_3nf.ce_booking_details
(
    booking_details_id BIGINT DEFAULT nextval('bl_3nf.seq_booking_details_id'),
    booking_details_src_id VARCHAR(1000) NOT NULL,
    market_segment VARCHAR(100) NOT NULL,
    distribution_channel VARCHAR(100) NOT NULL,
    deposit_type VARCHAR(100) NOT NULL,
    meal VARCHAR(100) NOT NULL,
    reservation_status VARCHAR(100) NOT NULL,
    is_canceled INT NOT NULL,
    adults INT NOT NULL,
    children INT NOT NULL,
    babies INT NOT NULL,
    required_car_parking_spaces INT NOT NULL,
    total_of_special_requests INT NOT NULL,
    insert_dt DATE NOT NULL,
    update_dt DATE NOT NULL,
    source_system VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    CONSTRAINT pk_ce_booking_details PRIMARY KEY(booking_details_id),
    CONSTRAINT uq_ce_booking_details_source UNIQUE(booking_details_src_id, source_system, source_entity)
);

CREATE TABLE bl_3nf.ce_customers_scd
(
    customer_id BIGINT DEFAULT nextval('bl_3nf.seq_customer_id'),
    customer_src_id VARCHAR(100) NOT NULL,
    customer_type VARCHAR(100) NOT NULL,
    country_id BIGINT NOT NULL,
    is_repeated_guest INT NOT NULL,
    previous_cancellations INT NOT NULL,
    previous_bookings_not_canceled INT NOT NULL,
    company VARCHAR(100) NOT NULL,
    agent VARCHAR(100) NOT NULL DEFAULT 'n. a.',
    start_dt TIMESTAMP NOT NULL,
    end_dt TIMESTAMP NOT NULL,
    is_active VARCHAR(1) NOT NULL,
    insert_dt DATE NOT NULL,
    update_dt DATE NOT NULL,
    source_system VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    CONSTRAINT pk_ce_customers_scd PRIMARY KEY(customer_id),
    CONSTRAINT uq_customer_version UNIQUE(customer_src_id, source_system, source_entity, start_dt),
    CONSTRAINT fk_customer_country FOREIGN KEY(country_id) REFERENCES bl_3nf.ce_countries(country_id)
);

CREATE TABLE bl_3nf.ce_bookings
(
    booking_id BIGINT DEFAULT nextval('bl_3nf.seq_booking_id'),
    booking_src_id VARCHAR(100) NOT NULL,
    hotel_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,
    room_id BIGINT NOT NULL,
    booking_details_id BIGINT NOT NULL,
    arrival_date_src_id VARCHAR(50),
    reservation_status_date_src_id VARCHAR(50),
    lead_time INT NOT NULL,
    total_nights INT NOT NULL,
    booking_changes INT NOT NULL,
    days_in_waiting_list INT NOT NULL,
    adr NUMERIC(12,4) NOT NULL,
    sales_amount NUMERIC(12,4) NOT NULL,
    cost_amount NUMERIC(12,4) NOT NULL,
    profit_amount NUMERIC(12,4) NOT NULL,
    insert_dt DATE NOT NULL,
    update_dt DATE NOT NULL,
    source_system VARCHAR(100) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    CONSTRAINT pk_ce_bookings PRIMARY KEY(booking_id),
    CONSTRAINT uq_ce_bookings_source UNIQUE(booking_src_id, source_system, source_entity),
    CONSTRAINT fk_booking_hotel FOREIGN KEY(hotel_id) REFERENCES bl_3nf.ce_hotels(hotel_id),
    CONSTRAINT fk_booking_customer FOREIGN KEY(customer_id) REFERENCES bl_3nf.ce_customers_scd(customer_id),
    CONSTRAINT fk_booking_room FOREIGN KEY(room_id) REFERENCES bl_3nf.ce_rooms(room_id),
    CONSTRAINT fk_booking_details FOREIGN KEY(booking_details_id) REFERENCES bl_3nf.ce_booking_details(booking_details_id)
);

INSERT INTO bl_3nf.ce_countries VALUES (-1,'n. a.','n. a.',DATE '1900-01-01',DATE '1900-01-01','DEFAULT','DEFAULT') ON CONFLICT DO NOTHING;
INSERT INTO bl_3nf.ce_cities VALUES (-1,'n. a.','n. a.',-1,DATE '1900-01-01',DATE '1900-01-01','DEFAULT','DEFAULT') ON CONFLICT DO NOTHING;
INSERT INTO bl_3nf.ce_hotels VALUES (-1,'n. a.','n. a.',-1,DATE '1900-01-01',DATE '1900-01-01','DEFAULT','DEFAULT') ON CONFLICT DO NOTHING;
INSERT INTO bl_3nf.ce_rooms VALUES (-1,'n. a.',-1,'n. a.','n. a.','n. a.',DATE '1900-01-01',DATE '1900-01-01','DEFAULT','DEFAULT') ON CONFLICT DO NOTHING;
INSERT INTO bl_3nf.ce_booking_details VALUES (-1,'n. a.','n. a.','n. a.','n. a.','n. a.','n. a.',-1,-1,-1,-1,-1,-1,DATE '1900-01-01',DATE '1900-01-01','DEFAULT','DEFAULT') ON CONFLICT DO NOTHING;
INSERT INTO bl_3nf.ce_customers_scd VALUES (-1,'n. a.','n. a.',-1,-1,-1,-1,'n. a.','n. a.',DATE '1900-01-01',DATE '9999-12-31','Y',DATE '1900-01-01',DATE '1900-01-01','DEFAULT','DEFAULT') ON CONFLICT DO NOTHING;

COMMIT;
