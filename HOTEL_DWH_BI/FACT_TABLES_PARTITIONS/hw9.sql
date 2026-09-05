--i applied dbeaver default formatter to all my scripts.

CREATE OR REPLACE PROCEDURE bl_cl.load_ce_bookings()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected BIGINT := 0;
BEGIN
    INSERT INTO bl_3nf.ce_bookings AS dest
    (
        booking_src_id,
        hotel_id,
        customer_id,
        room_id,
        booking_details_id,
        arrival_date_src_id,
        reservation_status_date_src_id,
        lead_time,
        total_nights,
        booking_changes,
        days_in_waiting_list,
        adr,
        sales_amount,
        cost_amount,
        profit_amount,
        insert_dt,
        update_dt,
        source_system,
        source_entity
    )
    SELECT
        s.booking_id::VARCHAR,
        COALESCE(h.hotel_id, -1),
        COALESCE(c.customer_id, -1),
        COALESCE(r.room_id, -1),
        COALESCE(bd.booking_details_id, -1),
        s.arrival_date_year::VARCHAR || '-' || s.arrival_date_month::VARCHAR || '-01',
        s.reservation_status_date::VARCHAR,
        COALESCE(s.lead_time::INTEGER, 0),
        COALESCE(s.stays_in_weekend_nights::INTEGER + s.stays_in_week_nights::INTEGER, 0),
        COALESCE(s.booking_changes::INTEGER, 0),
        COALESCE(s.days_in_waiting_list::INTEGER, 0),
        COALESCE(s.adr::NUMERIC, 0),
        COALESCE(
            s.adr::NUMERIC *
            (s.stays_in_weekend_nights::INTEGER + s.stays_in_week_nights::INTEGER),
            0
        ),
        COALESCE(
            s.adr::NUMERIC *
            (s.stays_in_weekend_nights::INTEGER + s.stays_in_week_nights::INTEGER) * 0.70,
            0
        ),
        COALESCE(
            s.adr::NUMERIC *
            (s.stays_in_weekend_nights::INTEGER + s.stays_in_week_nights::INTEGER) * 0.30,
            0
        ),
        CURRENT_DATE,
        CURRENT_DATE,
        s.source_system,
        s.source_table
    FROM
    (
        SELECT * FROM sa_city_hotel.src_city_hotel
        UNION ALL
        SELECT * FROM sa_resort_hotel.src_resort_hotel
    ) AS s
    LEFT JOIN bl_3nf.ce_hotels h
      ON h.hotel_src_id = s.hotel::VARCHAR
     AND h.source_system = s.source_system
     AND h.source_entity = s.source_table
    LEFT JOIN bl_3nf.ce_customers_scd c
      ON c.customer_src_id = s.customer_src_id::VARCHAR
     AND c.source_system = s.source_system
     AND c.source_entity = s.source_table
     AND c.is_active = 'Y'
    LEFT JOIN bl_3nf.ce_rooms r
      ON r.room_src_id =
            COALESCE(NULLIF(BTRIM(s.hotel), ''), 'n. a.') || '~' ||
            COALESCE(NULLIF(BTRIM(s.reserved_room_type), ''), 'n. a.') || '~' ||
            COALESCE(NULLIF(BTRIM(s.assigned_room_type), ''), 'n. a.') || '~' ||
            COALESCE(NULLIF(BTRIM(s.product_bundle_name), ''), 'n. a.')
     AND r.source_system = s.source_system
     AND r.source_entity = s.source_table
    LEFT JOIN bl_3nf.ce_booking_details bd
      ON bd.booking_details_src_id =
            COALESCE(NULLIF(BTRIM(s.market_segment), ''), 'n. a.') || '~' ||
            COALESCE(NULLIF(BTRIM(s.distribution_channel), ''), 'n. a.') || '~' ||
            COALESCE(NULLIF(BTRIM(s.deposit_type), ''), 'n. a.') || '~' ||
            COALESCE(NULLIF(BTRIM(s.meal), ''), 'n. a.') || '~' ||
            COALESCE(NULLIF(BTRIM(s.reservation_status), ''), 'n. a.') || '~' ||
            COALESCE(NULLIF(BTRIM(s.is_canceled), ''), '-1') || '~' ||
            COALESCE(NULLIF(BTRIM(s.adults), ''), '-1') || '~' ||
            COALESCE(NULLIF(BTRIM(s.children), ''), '-1') || '~' ||
            COALESCE(NULLIF(BTRIM(s.babies), ''), '-1') || '~' ||
            COALESCE(NULLIF(BTRIM(s.required_car_parking_spaces), ''), '-1') || '~' ||
            COALESCE(NULLIF(BTRIM(s.total_of_special_requests), ''), '-1')
     AND bd.source_system = s.source_system
     AND bd.source_entity = s.source_table
    ON CONFLICT (booking_src_id, source_system, source_entity)
    DO UPDATE SET
        hotel_id = EXCLUDED.hotel_id,
        customer_id = EXCLUDED.customer_id,
        room_id = EXCLUDED.room_id,
        booking_details_id = EXCLUDED.booking_details_id,
        arrival_date_src_id = EXCLUDED.arrival_date_src_id,
        reservation_status_date_src_id = EXCLUDED.reservation_status_date_src_id,
        lead_time = EXCLUDED.lead_time,
        total_nights = EXCLUDED.total_nights,
        booking_changes = EXCLUDED.booking_changes,
        days_in_waiting_list = EXCLUDED.days_in_waiting_list,
        adr = EXCLUDED.adr,
        sales_amount = EXCLUDED.sales_amount,
        cost_amount = EXCLUDED.cost_amount,
        profit_amount = EXCLUDED.profit_amount,
        update_dt = CURRENT_DATE;

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    CALL bl_cl.insert_etl_log(
        'load_ce_bookings',
        v_rows_affected,
        '3NF bookings loaded successfully'
    );
EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.insert_etl_log(
            'load_ce_bookings',
            0,
            LEFT(SQLERRM, 1000),
            'FAILED',
            SQLSTATE
        );
        RAISE;
END;
$$;


CREATE TABLE bl_dm.fct_bookings
(
    booking_id bigint GENERATED ALWAYS AS IDENTITY
        (SEQUENCE NAME bl_dm.fct_bookings_booking_id_seq),
    booking_src_id varchar(250) NOT NULL,

    hotel_surr_id bigint NOT NULL,
    customer_surr_id bigint NOT NULL,
    room_surr_id bigint NOT NULL,
    channel_surr_id bigint NOT NULL,
    status_surr_id bigint NOT NULL,
    arrival_time_surr_id bigint NOT NULL,
    reservation_status_time_surr_id bigint NOT NULL,

    lead_time integer NOT NULL,
    total_nights integer NOT NULL,
    booking_changes integer NOT NULL,
    days_in_waiting_list integer NOT NULL,
    adr NUMERIC(10, 4),
    sales_amount NUMERIC(10, 4),
    cost_amount NUMERIC(10, 4),

    insert_dt date NOT NULL,
    update_dt date NOT NULL,
    source_system varchar(100) NOT NULL,
    source_entity varchar(100) NOT NULL,

    CONSTRAINT fct_bookings_pkey
        PRIMARY KEY (booking_id,
arrival_time_surr_id)
)
PARTITION BY RANGE (arrival_time_surr_id);

CREATE TABLE bl_dm.fct_bookings_before_2024
PARTITION OF bl_dm.fct_bookings
FOR
VALUES
FROM
(MINVALUE) TO (40905);

CREATE TABLE bl_dm.fct_bookings_2024
PARTITION OF bl_dm.fct_bookings
FOR
VALUES
FROM
(40905) TO (43833);

CREATE TABLE bl_dm.fct_bookings_2025_h1
PARTITION OF bl_dm.fct_bookings
FOR
VALUES
FROM
(43833) TO (45281);

CREATE TABLE bl_dm.fct_bookings_2025_q3
PARTITION OF bl_dm.fct_bookings
FOR
VALUES
FROM
(45281) TO (46017);

CREATE TABLE bl_dm.fct_bookings_after_2025_q3
PARTITION OF bl_dm.fct_bookings
FOR
VALUES
FROM
(46017) TO (MAXVALUE);



CREATE OR REPLACE PROCEDURE bl_cl.load_fct_bookings_dm()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected BIGINT := 0;
BEGIN
    MERGE INTO bl_dm.fct_bookings AS dest
    USING
    (
        SELECT
            b.booking_src_id,
            COALESCE(h.hotel_surr_id, -1) AS hotel_surr_id,
            COALESCE(c.customer_surr_id, -1) AS customer_surr_id,
            COALESCE(r.room_surr_id, -1) AS room_surr_id,
            COALESCE(ch.channel_surr_id, -1) AS channel_surr_id,
            COALESCE(st.status_surr_id, -1) AS status_surr_id,
            COALESCE(arr.time_id, -1) AS arrival_time_surr_id,
            COALESCE(res.time_id, -1) AS reservation_status_time_surr_id,
            b.lead_time,
            b.total_nights,
            b.booking_changes,
            b.days_in_waiting_list,
            b.adr,
            b.sales_amount,
            b.cost_amount,
            CURRENT_DATE AS insert_dt,
            CURRENT_DATE AS update_dt,
            b.source_system,
            b.source_entity
        FROM bl_3nf.ce_bookings b
        LEFT JOIN bl_3nf.ce_hotels h3
          ON h3.hotel_id = b.hotel_id
        LEFT JOIN bl_dm.dim_hotels h
          ON h.hotel_src_id = h3.hotel_src_id
         AND h.source_system = h3.source_system
         AND h.source_entity = h3.source_entity
        LEFT JOIN bl_3nf.ce_customers_scd c3
          ON c3.customer_id = b.customer_id
         AND c3.is_active = 'Y'
        LEFT JOIN bl_dm.dim_customers c
          ON c.customer_src_id = c3.customer_src_id
         AND c.source_system = c3.source_system
         AND c.source_entity = c3.source_entity
         AND clock_timestamp() BETWEEN c.start_dt AND c.end_dt
        LEFT JOIN bl_3nf.ce_rooms r3
          ON r3.room_id = b.room_id
        LEFT JOIN bl_dm.dim_rooms r
          ON r.room_src_id = r3.room_src_id
         AND r.source_system = r3.source_system
         AND r.source_entity = r3.source_entity
        LEFT JOIN bl_dm.dim_times arr
          ON arr.time_actual = b.arrival_date_src_id::DATE::TIMESTAMP
        LEFT JOIN bl_dm.dim_times res
          ON res.time_actual = b.reservation_status_date_src_id::DATE::TIMESTAMP
        LEFT JOIN bl_3nf.ce_booking_details bd
          ON bd.booking_details_id = b.booking_details_id
		   LEFT JOIN bl_dm.dim_channels ch
          ON ch.market_segment = bd.market_segment
         AND ch.distribution_channel = bd.distribution_channel
         AND ch.source_system = bd.source_system
         AND ch.source_entity = bd.source_entity
        LEFT JOIN bl_dm.dim_reservation_statuses st
          ON st.reservation_status = bd.reservation_status
         AND st.is_canceled = bd.is_canceled
         AND st.deposit_type = bd.deposit_type
         AND st.meal = bd.meal
         AND st.adults = bd.adults
         AND st.children = bd.children
         AND st.babies = bd.babies
         AND st.required_car_parking_spaces = bd.required_car_parking_spaces
         AND st.total_of_special_requests = bd.total_of_special_requests
         AND st.source_system = bd.source_system
         AND st.source_entity = bd.source_entity
        WHERE b.booking_id <> -1
    ) AS src
    ON  dest.booking_src_id = src.booking_src_id
    AND dest.source_system = src.source_system
    AND dest.source_entity = src.source_entity
    WHEN MATCHED AND
    (
        dest.hotel_surr_id IS DISTINCT FROM src.hotel_surr_id
        OR dest.customer_surr_id IS DISTINCT FROM src.customer_surr_id
        OR dest.room_surr_id IS DISTINCT FROM src.room_surr_id
        OR dest.channel_surr_id IS DISTINCT FROM src.channel_surr_id
        OR dest.status_surr_id IS DISTINCT FROM src.status_surr_id
        OR dest.arrival_time_surr_id IS DISTINCT FROM src.arrival_time_surr_id
        OR dest.reservation_status_time_surr_id IS DISTINCT FROM src.reservation_status_time_surr_id
        OR dest.lead_time IS DISTINCT FROM src.lead_time
        OR dest.total_nights IS DISTINCT FROM src.total_nights
        OR dest.booking_changes IS DISTINCT FROM src.booking_changes
        OR dest.days_in_waiting_list IS DISTINCT FROM src.days_in_waiting_list
        OR dest.adr IS DISTINCT FROM src.adr
        OR dest.sales_amount IS DISTINCT FROM src.sales_amount
        OR dest.cost_amount IS DISTINCT FROM src.cost_amount
    ) THEN
        UPDATE SET
            hotel_surr_id = src.hotel_surr_id,
            customer_surr_id = src.customer_surr_id,
            room_surr_id = src.room_surr_id,
            channel_surr_id = src.channel_surr_id,
            status_surr_id = src.status_surr_id,
            arrival_time_surr_id = src.arrival_time_surr_id,
            reservation_status_time_surr_id = src.reservation_status_time_surr_id,
            lead_time = src.lead_time,
            total_nights = src.total_nights,
            booking_changes = src.booking_changes,
            days_in_waiting_list = src.days_in_waiting_list,
            adr = src.adr,
            sales_amount = src.sales_amount,
            cost_amount = src.cost_amount,
            update_dt = src.update_dt
    WHEN NOT MATCHED THEN
        INSERT
        (
            booking_src_id,
            hotel_surr_id,
            customer_surr_id,
            room_surr_id,
            channel_surr_id,
            status_surr_id,
            arrival_time_surr_id,
            reservation_status_time_surr_id,
            lead_time,
            total_nights,
            booking_changes,
            days_in_waiting_list,
            adr,
            sales_amount,
            cost_amount,
            insert_dt,
            update_dt,
            source_system,
            source_entity
        )
        VALUES
        (
            src.booking_src_id,
            src.hotel_surr_id,
            src.customer_surr_id,
            src.room_surr_id,
            src.channel_surr_id,
            src.status_surr_id,
            src.arrival_time_surr_id,
            src.reservation_status_time_surr_id,
            src.lead_time,
            src.total_nights,
            src.booking_changes,
            src.days_in_waiting_list,
            src.adr,
            src.sales_amount,
            src.cost_amount,
            src.insert_dt,
            src.update_dt,
            src.source_system,
            src.source_entity
        );

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    CALL bl_cl.insert_etl_log(
        'load_fct_bookings_dm',
        v_rows_affected,
        'DM fact bookings loaded successfully'
    );
EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.insert_etl_log(
            'load_fct_bookings_dm',
            0,
            LEFT(SQLERRM, 1000),
            'FAILED',
            SQLSTATE
        );
        RAISE;
END;
$$;

