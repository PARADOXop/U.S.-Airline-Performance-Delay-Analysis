USE FlightAnalysis;

-- 1. If we create flight date column then we wont need year, month and date column

ALTER TABLE flights
drop column if exists flight_date;


ALTER TABLE flights
ADD flight_date AS CAST(scheduled_departure_dttime AS DATE);



-- 2. Add derived delay columns
ALTER TABLE flights
ADD departure_delay_min AS departure_delay,
    arrival_delay_min AS arrival_delay,
    departure_delay_cat AS
        CASE 
            WHEN departure_delay <= 0 THEN 'On-time'
            WHEN departure_delay BETWEEN 1 AND 30 THEN 'Short'
            WHEN departure_delay BETWEEN 31 AND 120 THEN 'Medium'
            ELSE 'Long'
        END,
    arrival_delay_cat AS
        CASE 
            WHEN arrival_delay <= 0 THEN 'On-time'
            WHEN arrival_delay BETWEEN 1 AND 30 THEN 'Short'
            WHEN arrival_delay BETWEEN 31 AND 120 THEN 'Medium'
            ELSE 'Long'
        END;


-- 3. Flight duration and average speed

ALTER TABLE flights
DROP COLUMN IF EXISTS actual_air_time, avg_speed;


ALTER TABLE flights
ADD actual_air_time AS DATEDIFF(MINUTE, wheels_off_dttime, wheels_on_dttime),
    avg_speed AS CASE 
                    WHEN DATEDIFF(MINUTE, wheels_off_dttime, wheels_on_dttime) > 0 
                    THEN distance * 60.0 / DATEDIFF(MINUTE, wheels_off_dttime, wheels_on_dttime) 
                    ELSE NULL 
                 END;


ALTER TABLE flights
ADD actual_air_time AS DATEDIFF(MINUTE, wheels_off_dttime, wheels_on_dttime) PERSISTED,
    avg_speed AS CASE 
                    WHEN DATEDIFF(MINUTE, wheels_off_dttime, wheels_on_dttime) > 0 
                    THEN distance * 60.0 / DATEDIFF(MINUTE, wheels_off_dttime, wheels_on_dttime) 
                    ELSE NULL 
                 END;



-- 4. Route column
ALTER TABLE flights
ADD route AS origin_airport + '->' + destination_airport;


-- 5. Flight status based on cancellation/diversion
ALTER TABLE flights
ADD flight_status AS 
    CASE 
        WHEN cancelled = 1 THEN 'Cancelled'
        WHEN diverted = 1 THEN 'Diverted'
        ELSE 'Completed'
    END;


-- 6. Create a more descriptive cancellation reason (already mapped, just ensure column exists)
IF COL_LENGTH('flights','cancellation_reason_desc') IS NULL
BEGIN
    ALTER TABLE flights
    ADD cancellation_reason_desc AS
       CASE cancellation_reason
            WHEN 'A' THEN 'Air System'
            WHEN 'B' THEN 'Security'
            WHEN 'C' THEN 'Airline'
            WHEN 'D' THEN 'Weather'
       END;
END



-- 7. Quick validation: check top 10 rows
SELECT TOP 10 *
FROM flights;


-- 8. Check null counts for key columns after transformations
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN departure_delay_min IS NULL THEN 1 ELSE 0 END) AS null_departure_delay,
    SUM(CASE WHEN arrival_delay_min IS NULL THEN 1 ELSE 0 END) AS null_arrival_delay,
    SUM(CASE WHEN flight_status IS NULL THEN 1 ELSE 0 END) AS null_status,
    SUM(CASE WHEN actual_air_time IS NULL THEN 1 ELSE 0 END) AS null_air_time,
    SUM(CASE WHEN avg_speed IS NULL THEN 1 ELSE 0 END) AS null_avg_speed
FROM flights;

