--i applied dbeaver default formatter to all my scripts.
CREATE USER dwh_etl WITH PASSWORD '1234';
GRANT USAGE, CREATE ON SCHEMA bl_cl TO dwh_etl;
GRANT USAGE ON SCHEMA bl_3nf TO dwh_etl;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA bl_3nf TO dwh_etl;
ALTER DEFAULT PRIVILEGES IN SCHEMA bl_3nf
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO dwh_etl;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA bl_3nf TO dwh_etl;

GRANT USAGE ON SCHEMA sa_city_hotel TO dwh_etl;
GRANT SELECT ON sa_city_hotel.src_city_hotel TO dwh_etl;
GRANT USAGE ON SCHEMA sa_resort_hotel TO dwh_etl;
GRANT SELECT ON sa_resort_hotel.src_resort_hotel TO dwh_etl;

CREATE OR REPLACE PROCEDURE bl_cl.load_ce_countries()
LANGUAGE plpgsql
AS $$
DECLARE
    v_country       RECORD;
    v_rows_affected BIGINT := 0;
    v_step_rows     BIGINT := 0;
BEGIN
    FOR v_country IN
        SELECT
            s.country_src_id,
            MAX(s.country_name) AS country_name,
            s.source_system,
            s.source_entity
        FROM
        (
            SELECT
                NULLIF(BTRIM(country), '') AS country_src_id,
                COALESCE(NULLIF(BTRIM(country_name), ''), 'n. a.') AS country_name,
                source_system,
                source_table AS source_entity
            FROM sa_city_hotel.src_city_hotel

            UNION ALL

            SELECT
                NULLIF(BTRIM(country), ''),
                COALESCE(NULLIF(BTRIM(country_name), ''), 'n. a.'),
                source_system,
                source_table
            FROM sa_resort_hotel.src_resort_hotel
        ) s
        WHERE s.country_src_id IS NOT NULL
        GROUP BY
            s.country_src_id,
            s.source_system,
            s.source_entity
    LOOP
        INSERT INTO bl_3nf.ce_countries AS dest
        (
            country_src_id,
            country_name,
            insert_dt,
            update_dt,
            source_system,
            source_entity
        )
        VALUES
        (
            v_country.country_src_id,
            v_country.country_name,
            CURRENT_DATE,
            CURRENT_DATE,
            v_country.source_system,
            v_country.source_entity
        )
        ON CONFLICT (country_src_id, source_system, source_entity)
        DO UPDATE SET
            country_name = EXCLUDED.country_name,
            update_dt = CURRENT_DATE
        WHERE dest.country_name IS DISTINCT FROM EXCLUDED.country_name;

        GET DIAGNOSTICS v_step_rows = ROW_COUNT;
        v_rows_affected := v_rows_affected + v_step_rows;
    END LOOP;

    CALL bl_cl.insert_etl_log
    (
        'load_ce_countries',
        v_rows_affected,
        'countries loaded successfully'
    );
EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.insert_etl_log
        (
            'load_ce_countries',
            0,
            LEFT(SQLERRM, 1000),
            'FAILED',
            SQLSTATE
        );
        RAISE;
END;
$$;

CREATE OR REPLACE PROCEDURE bl_cl.load_ce_cities()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected BIGINT := 0;
BEGIN
    INSERT INTO bl_3nf.ce_cities AS dest
    (
        city_src_id,
        city_name,
        country_id,
        insert_dt,
        update_dt,
        source_system,
        source_entity
    )
    SELECT
        s.city_src_id,
        s.city_name,
        COALESCE(c.country_id, -1),
        CURRENT_DATE,
        CURRENT_DATE,
        s.source_system,
        s.source_entity
    FROM
    (
        SELECT
            city_src_id,
            MAX(city_name) AS city_name,
            MAX(country_src_id) AS country_src_id,
            source_system,
            source_entity
        FROM
        (
            SELECT
                NULLIF(BTRIM(city_name), '') AS city_src_id,
                COALESCE(NULLIF(BTRIM(city_name), ''), 'n. a.') AS city_name,
                NULLIF(BTRIM(country), '') AS country_src_id,
                source_system,
                source_table AS source_entity
            FROM sa_city_hotel.src_city_hotel

            UNION ALL

            SELECT
                NULLIF(BTRIM(city_name), ''),
                COALESCE(NULLIF(BTRIM(city_name), ''), 'n. a.'),
                NULLIF(BTRIM(country), ''),
                source_system,
                source_table
            FROM sa_resort_hotel.src_resort_hotel
        ) x
        WHERE city_src_id IS NOT NULL
        GROUP BY city_src_id, source_system, source_entity
    ) s
    LEFT JOIN bl_3nf.ce_countries c
        ON c.country_src_id = s.country_src_id
        AND c.source_system = s.source_system
        AND c.source_entity = s.source_entity
    ON CONFLICT (city_src_id, source_system, source_entity)
    DO UPDATE SET
        city_name = EXCLUDED.city_name,
        country_id = EXCLUDED.country_id,
        update_dt = CURRENT_DATE
    WHERE dest.city_name IS DISTINCT FROM EXCLUDED.city_name
       OR dest.country_id IS DISTINCT FROM EXCLUDED.country_id;

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

    CALL bl_cl.insert_etl_log
    (
        'load_ce_cities',
        v_rows_affected,
        'cities loaded successfully'
    );
EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.insert_etl_log
        (
            'load_ce_cities',
            0,
            LEFT(SQLERRM, 1000),
            'FAILED',
            SQLSTATE
        );
        RAISE;
END;
$$;

CREATE OR REPLACE PROCEDURE bl_cl.load_ce_hotels()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected BIGINT := 0;
BEGIN
    INSERT INTO bl_3nf.ce_hotels AS dest
    (
        hotel_src_id,
        hotel_name,
        city_id,
        insert_dt,
        update_dt,
        source_system,
        source_entity
    )
    SELECT
        s.hotel_src_id,
        s.hotel_name,
        COALESCE(c.city_id, -1),
        CURRENT_DATE,
        CURRENT_DATE,
        s.source_system,
        s.source_entity
    FROM
    (
        SELECT
            hotel_src_id,
            MAX(hotel_name) AS hotel_name,
            MAX(city_src_id) AS city_src_id,
            source_system,
            source_entity
        FROM
        (
            SELECT
                NULLIF(BTRIM(hotel), '') AS hotel_src_id,
                COALESCE(NULLIF(BTRIM(hotel_name), ''), NULLIF(BTRIM(hotel), ''), 'n. a.') AS hotel_name,
                NULLIF(BTRIM(city_name), '') AS city_src_id,
                source_system,
                source_table AS source_entity
            FROM sa_city_hotel.src_city_hotel

            UNION ALL

            SELECT
                NULLIF(BTRIM(hotel), ''),
                COALESCE(NULLIF(BTRIM(hotel_name), ''), NULLIF(BTRIM(hotel), ''), 'n. a.'),
                NULLIF(BTRIM(city_name), ''),
                source_system,
                source_table
            FROM sa_resort_hotel.src_resort_hotel
        ) x
        WHERE hotel_src_id IS NOT NULL
        GROUP BY hotel_src_id, source_system, source_entity
    ) s
    LEFT JOIN bl_3nf.ce_cities c
        ON c.city_src_id = s.city_src_id
        AND c.source_system = s.source_system
        AND c.source_entity = s.source_entity
    ON CONFLICT (hotel_src_id, source_system, source_entity)
    DO UPDATE SET
        hotel_name = EXCLUDED.hotel_name,
        city_id = EXCLUDED.city_id,
        update_dt = CURRENT_DATE
    WHERE dest.hotel_name IS DISTINCT FROM EXCLUDED.hotel_name
       OR dest.city_id IS DISTINCT FROM EXCLUDED.city_id;

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

    CALL bl_cl.insert_etl_log
    (
        'load_ce_hotels',
        v_rows_affected,
        'hotels loaded successfully'
    );
EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.insert_etl_log
        (
            'load_ce_hotels',
            0,
            LEFT(SQLERRM, 1000),
            'FAILED',
            SQLSTATE
        );
        RAISE;
END;
$$;

CREATE OR REPLACE PROCEDURE bl_cl.load_ce_rooms()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected BIGINT := 0;
BEGIN
    INSERT INTO bl_3nf.ce_rooms AS dest
    (
        room_src_id,
        hotel_id,
        reserved_room_type,
        assigned_room_type,
        product_bundle,
        insert_dt,
        update_dt,
        source_system,
        source_entity
    )
    SELECT DISTINCT
        COALESCE(NULLIF(BTRIM(s.hotel), ''), 'n. a.') || '~' ||
        COALESCE(NULLIF(BTRIM(s.reserved_room_type), ''), 'n. a.') || '~' ||
        COALESCE(NULLIF(BTRIM(s.assigned_room_type), ''), 'n. a.') || '~' ||
        COALESCE(NULLIF(BTRIM(s.product_bundle_name), ''), 'n. a.'),
        COALESCE(h.hotel_id, -1),
        COALESCE(NULLIF(BTRIM(s.reserved_room_type), ''), 'n. a.'),
        COALESCE(NULLIF(BTRIM(s.assigned_room_type), ''), 'n. a.'),
        COALESCE(NULLIF(BTRIM(s.product_bundle_name), ''), 'n. a.'),
        CURRENT_DATE,
        CURRENT_DATE,
        s.source_system,
        s.source_table
    FROM
    (
        SELECT * FROM sa_city_hotel.src_city_hotel
        UNION ALL
        SELECT * FROM sa_resort_hotel.src_resort_hotel
    ) s
    LEFT JOIN bl_3nf.ce_hotels h
        ON h.hotel_src_id = COALESCE(NULLIF(BTRIM(s.hotel), ''), 'n. a.')
        AND h.source_system = s.source_system
        AND h.source_entity = s.source_table
    ON CONFLICT (room_src_id, source_system, source_entity)
    DO UPDATE SET
        hotel_id = EXCLUDED.hotel_id,
        reserved_room_type = EXCLUDED.reserved_room_type,
        assigned_room_type = EXCLUDED.assigned_room_type,
        product_bundle = EXCLUDED.product_bundle,
        update_dt = CURRENT_DATE
    WHERE dest.hotel_id IS DISTINCT FROM EXCLUDED.hotel_id
       OR dest.reserved_room_type IS DISTINCT FROM EXCLUDED.reserved_room_type
       OR dest.assigned_room_type IS DISTINCT FROM EXCLUDED.assigned_room_type
       OR dest.product_bundle IS DISTINCT FROM EXCLUDED.product_bundle;

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

    CALL bl_cl.insert_etl_log
    (
        'load_ce_rooms',
        v_rows_affected,
        'rooms loaded successfully'
    );
EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.insert_etl_log
        (
            'load_ce_rooms',
            0,
            LEFT(SQLERRM, 1000),
            'FAILED',
            SQLSTATE
        );
        RAISE;
END;
$$;

CREATE OR REPLACE PROCEDURE bl_cl.load_ce_booking_details()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_affected BIGINT := 0;
BEGIN
    INSERT INTO bl_3nf.ce_booking_details
    (
        booking_details_src_id,
        market_segment,
        distribution_channel,
        deposit_type,
        meal,
        reservation_status,
        is_canceled,
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
    SELECT DISTINCT
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
        COALESCE(NULLIF(BTRIM(s.total_of_special_requests), ''), '-1'),
        COALESCE(NULLIF(BTRIM(s.market_segment), ''), 'n. a.'),
        COALESCE(NULLIF(BTRIM(s.distribution_channel), ''), 'n. a.'),
        COALESCE(NULLIF(BTRIM(s.deposit_type), ''), 'n. a.'),
        COALESCE(NULLIF(BTRIM(s.meal), ''), 'n. a.'),
        COALESCE(NULLIF(BTRIM(s.reservation_status), ''), 'n. a.'),
        COALESCE(NULLIF(BTRIM(s.is_canceled), '')::NUMERIC::INTEGER, -1),
        COALESCE(NULLIF(BTRIM(s.adults), '')::NUMERIC::INTEGER, -1),
        COALESCE(NULLIF(BTRIM(s.children), '')::NUMERIC::INTEGER, -1),
        COALESCE(NULLIF(BTRIM(s.babies), '')::NUMERIC::INTEGER, -1),
        COALESCE(NULLIF(BTRIM(s.required_car_parking_spaces), '')::NUMERIC::INTEGER, -1),
        COALESCE(NULLIF(BTRIM(s.total_of_special_requests), '')::NUMERIC::INTEGER, -1),
        CURRENT_DATE,
        CURRENT_DATE,
        s.source_system,
        s.source_table
    FROM
    (
        SELECT * FROM sa_city_hotel.src_city_hotel
        UNION ALL
        SELECT * FROM sa_resort_hotel.src_resort_hotel
    ) s
    ON CONFLICT (booking_details_src_id, source_system, source_entity)
    DO NOTHING;

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

    CALL bl_cl.insert_etl_log
    (
        'load_ce_booking_details',
        v_rows_affected,
        'booking details loaded successfully'
    );
EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.insert_etl_log
        (
            'load_ce_booking_details',
            0,
            LEFT(SQLERRM, 1000),
            'FAILED',
            SQLSTATE
        );
        RAISE;
END;
$$;

CREATE OR REPLACE FUNCTION bl_cl.get_customer_src_data()
RETURNS TABLE
(
    customer_src_id                VARCHAR,
    customer_type                  VARCHAR,
    country_id                     BIGINT,
    is_repeated_guest              INTEGER,
    previous_cancellations         INTEGER,
    previous_bookings_not_canceled INTEGER,
    company                        VARCHAR,
    agent                          VARCHAR,
    source_system                  VARCHAR,
    source_entity                  VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH source_data AS
    (
        SELECT
            NULLIF(BTRIM(s.customer_src_id), '')::VARCHAR AS customer_src_id,
            COALESCE(NULLIF(BTRIM(s.customer_type), ''), 'n. a.')::VARCHAR AS customer_type,
            COALESCE(c.country_id, -1)::BIGINT AS country_id,
            COALESCE(NULLIF(BTRIM(s.is_repeated_guest), '')::NUMERIC::INTEGER, -1) AS is_repeated_guest,
            COALESCE(NULLIF(BTRIM(s.previous_cancellations), '')::NUMERIC::INTEGER, -1) AS previous_cancellations,
            COALESCE(NULLIF(BTRIM(s.previous_bookings_not_canceled), '')::NUMERIC::INTEGER, -1) AS previous_bookings_not_canceled,
            COALESCE(NULLIF(BTRIM(s.company), ''), 'n. a.')::VARCHAR AS company,
            COALESCE(NULLIF(BTRIM(s.agent), ''), 'n. a.')::VARCHAR AS agent,
            s.source_system::VARCHAR AS source_system,
            s.source_table::VARCHAR AS source_entity,
            s.load_dts,
            s.booking_src_id
        FROM sa_city_hotel.src_city_hotel s
        LEFT JOIN bl_3nf.ce_countries c
            ON c.country_src_id = NULLIF(BTRIM(s.country), '')
            AND c.source_system = s.source_system
            AND c.source_entity = s.source_table
        WHERE NULLIF(BTRIM(s.customer_src_id), '') IS NOT NULL

        UNION ALL

        SELECT
            NULLIF(BTRIM(s.customer_src_id), '')::VARCHAR,
            COALESCE(NULLIF(BTRIM(s.customer_type), ''), 'n. a.')::VARCHAR,
            COALESCE(c.country_id, -1)::BIGINT,
            COALESCE(NULLIF(BTRIM(s.is_repeated_guest), '')::NUMERIC::INTEGER, -1),
            COALESCE(NULLIF(BTRIM(s.previous_cancellations), '')::NUMERIC::INTEGER, -1),
            COALESCE(NULLIF(BTRIM(s.previous_bookings_not_canceled), '')::NUMERIC::INTEGER, -1),
            COALESCE(NULLIF(BTRIM(s.company), ''), 'n. a.')::VARCHAR,
            COALESCE(NULLIF(BTRIM(s.agent), ''), 'n. a.')::VARCHAR,
            s.source_system::VARCHAR,
            s.source_table::VARCHAR,
            s.load_dts,
            s.booking_src_id
        FROM sa_resort_hotel.src_resort_hotel s
        LEFT JOIN bl_3nf.ce_countries c
            ON c.country_src_id = NULLIF(BTRIM(s.country), '')
            AND c.source_system = s.source_system
            AND c.source_entity = s.source_table
        WHERE NULLIF(BTRIM(s.customer_src_id), '') IS NOT NULL
    ),
    ranked_source AS
    (
        SELECT
            source_data.*,
            ROW_NUMBER() OVER
            (
                PARTITION BY
                    source_data.customer_src_id,
                    source_data.source_system,
                    source_data.source_entity
                ORDER BY source_data.load_dts DESC, source_data.booking_src_id DESC
            ) AS row_num
        FROM source_data
    )
    SELECT
        ranked_source.customer_src_id,
        ranked_source.customer_type,
        ranked_source.country_id,
        ranked_source.is_repeated_guest,
        ranked_source.previous_cancellations,
        ranked_source.previous_bookings_not_canceled,
        ranked_source.company,
        ranked_source.agent,
        ranked_source.source_system,
        ranked_source.source_entity
    FROM ranked_source
    WHERE row_num = 1;
END;
$$;

CREATE OR REPLACE PROCEDURE bl_cl.load_ce_customers_scd()
LANGUAGE plpgsql
AS $$
DECLARE
    v_effective_ts TIMESTAMP := clock_timestamp();
    v_expired_rows BIGINT := 0;
    v_inserted_rows BIGINT := 0;
BEGIN
    UPDATE bl_3nf.ce_customers_scd AS old
    SET
        end_dt = v_effective_ts - INTERVAL '1 microsecond', --just before the new rec starts
        is_active = 'N',
        update_dt = CURRENT_DATE
    FROM bl_cl.get_customer_src_data() AS src
    WHERE old.customer_src_id = src.customer_src_id
      AND old.source_system = src.source_system
      AND old.source_entity = src.source_entity
      AND old.is_active = 'Y'
      AND (
          old.customer_type IS DISTINCT FROM src.customer_type
          OR old.country_id IS DISTINCT FROM src.country_id
          OR old.is_repeated_guest IS DISTINCT FROM src.is_repeated_guest
          OR old.previous_cancellations IS DISTINCT FROM src.previous_cancellations
          OR old.previous_bookings_not_canceled IS DISTINCT FROM src.previous_bookings_not_canceled
          OR old.company IS DISTINCT FROM src.company
          OR old.agent IS DISTINCT FROM src.agent
      );

    GET DIAGNOSTICS v_expired_rows = ROW_COUNT;

    INSERT INTO bl_3nf.ce_customers_scd
    (
        customer_src_id,
        customer_type,
        country_id,
        is_repeated_guest,
        previous_cancellations,
        previous_bookings_not_canceled,
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
        src.customer_src_id,
        src.customer_type,
        src.country_id,
        src.is_repeated_guest,
        src.previous_cancellations,
        src.previous_bookings_not_canceled,
        src.company,
        src.agent,
        v_effective_ts,
        TIMESTAMP '9999-12-31 23:59:59.999999',
        'Y',
        CURRENT_DATE,
        CURRENT_DATE,
        src.source_system,
        src.source_entity
    FROM bl_cl.get_customer_src_data() AS src
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM bl_3nf.ce_customers_scd AS old
        WHERE old.customer_src_id = src.customer_src_id
          AND old.source_system = src.source_system
          AND old.source_entity = src.source_entity
          AND old.is_active = 'Y'
    );

    GET DIAGNOSTICS v_inserted_rows = ROW_COUNT;

    CALL bl_cl.insert_etl_log(
        'load_ce_customers_scd',
        v_expired_rows + v_inserted_rows,
        'customers SCD Type 2 loaded successfully'
    );
EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.insert_etl_log(
            'load_ce_customers_scd',
            0,
            LEFT(SQLERRM, 1000),
            'FAILED',
            SQLSTATE
        );
        RAISE;
END;
$$;

GRANT SELECT, INSERT ON bl_cl.etl_log TO dwh_etl;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA bl_cl TO dwh_etl;
GRANT EXECUTE ON FUNCTION bl_cl.get_customer_src_data() TO dwh_etl;
GRANT EXECUTE ON PROCEDURE bl_cl.insert_etl_log
    (VARCHAR, BIGINT, VARCHAR, VARCHAR, VARCHAR) TO dwh_etl;
GRANT EXECUTE ON PROCEDURE bl_cl.load_ce_countries() TO dwh_etl;
GRANT EXECUTE ON PROCEDURE bl_cl.load_ce_cities() TO dwh_etl;
GRANT EXECUTE ON PROCEDURE bl_cl.load_ce_hotels() TO dwh_etl;
GRANT EXECUTE ON PROCEDURE bl_cl.load_ce_rooms() TO dwh_etl;
GRANT EXECUTE ON PROCEDURE bl_cl.load_ce_booking_details() TO dwh_etl;
GRANT EXECUTE ON PROCEDURE bl_cl.load_ce_customers_scd() TO dwh_etl;
