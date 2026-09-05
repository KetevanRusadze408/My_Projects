--i applied dbeaver default formatter to all my scripts.
CALL bl_cl.load_master_etl(
    p_city_csv_path => 'C:/Users/User/Desktop/updatecsv/city_hotel_initial_95_with_hotels.csv',
    p_resort_csv_path => 'C:/Users/User/Desktop/updatecsv/resort_hotel_initial_95_with_hotels.csv'
);

CALL bl_cl.load_master_etl(
    p_city_csv_path => 'C:/Users/User/Desktop/updatecsv/city_hotel_increment_5_with_hotels.csv',
    p_resort_csv_path => 'C:/Users/User/Desktop/updatecsv/resort_hotel_increment_5_with_hotels.csv'
);

SELECT *
FROM bl_cl.etl_log
ORDER BY log_id DESC;

--SCD2 test: 
SELECT
	customer_id,
	customer_src_id,
	customer_type,
	agent,
	company,
	start_dt,
	end_dt,
	is_active
FROM
	bl_3nf.ce_customers_scd
WHERE
	customer_src_id = 'GC100565'
ORDER BY
	start_dt DESC;


--after changing the fct_booking logic i updated booking changes from 40 to 41 and it was visible in the booking table as well
SELECT * 
FROM bl_dm.fct_bookings
WHERE booking_src_id= 'C0100564'
;

----other tests:
SELECT customer_src_id, source_system, source_entity,
COUNT(*) FILTER (WHERE is_active = 'Y') AS active_versions
FROM bl_3nf.ce_customers_scd
WHERE customer_id <> -1
GROUP BY customer_src_id, source_system, source_entity
HAVING COUNT(*) FILTER (WHERE is_active = 'Y') <> 1;

