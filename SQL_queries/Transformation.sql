USE FlightAnalysis;

-- 1) make a single date column so year/month/day aren’t needed later
ALTER TABLE flights
drop column if exists flight_date;

-- add computed flight_date from scheduled departure datetime (date only)
ALTER TABLE flights
ADD flight_date AS CAST(scheduled_departure_dttime AS DATE);

-- 2) add easy-to-read delay columns and buckets
ALTER TABLE flights
ADD departure_delay_min AS departure_delay,         -- copy in minutes
    arrival_delay_min AS arrival_delay,             -- copy in minutes
    departure_delay_cat AS                          -- bucket by size
        CASE 
            WHEN departure_delay <= 0 THEN 'On-time'
            WHEN departure_delay BETWEEN 1 AND 30 THEN 'Short'
            WHEN departure_delay BETWEEN 31 AND 120 THEN 'Medium'
            ELSE 'Long'
        END,
    arrival_delay_cat AS                            -- same buckets for arrival
        CASE 
            WHEN arrival_delay <= 0 THEN 'On-time'
            WHEN arrival_delay BETWEEN 1 AND 30 THEN 'Short'
            WHEN arrival_delay BETWEEN 31 AND 120 THEN 'Medium'
            ELSE 'Long'
        END;

-- 3) compute flight time and average speed
ALTER TABLE flights
DROP COLUMN IF EXISTS actual_air_time, avg_speed;   -- clean re-run

-- add computed columns (non-persisted first)
ALTER TABLE flights
ADD actual_air_time AS DATEDIFF(MINUTE, wheels_off_dttime, wheels_on_dttime), -- minutes in air
    avg_speed AS CASE 
                    WHEN DATEDIFF(MINUTE, wheels_off_dttime, wheels_on_dttime) > 0 
                    THEN distance * 60.0 / DATEDIFF(MINUTE, wheels_off_dttime, wheels_on_dttime) 
                    ELSE NULL 
                 END;

-- add persisted versions (stored on disk for performance)
ALTER TABLE flights
ADD actual_air_time AS DATEDIFF(MINUTE, wheels_off_dttime, wheels_on_dttime) PERSISTED,
    avg_speed AS CASE 
                    WHEN DATEDIFF(MINUTE, wheels_off_dttime, wheels_on_dttime) > 0 
                    THEN distance * 60.0 / DATEDIFF(MINUTE, wheels_off_dttime, wheels_on_dttime) 
                    ELSE NULL 
                 END;

-- 4) quick route label like ORG->DST
ALTER TABLE flights
ADD route AS origin_airport + '->' + destination_airport;

-- 5) readable flight status
ALTER TABLE flights
ADD flight_status AS 
    CASE 
        WHEN cancelled = 1 THEN 'Cancelled'
        WHEN diverted = 1 THEN 'Diverted'
        ELSE 'Completed'
    END;

-- 6) expanded cancellation reason text (add only if missing)
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

-- 7) peek at a few rows to sanity-check
SELECT TOP 10 *
FROM flights;

-- 8) null checks on key output columns after transformations
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN departure_delay_min IS NULL THEN 1 ELSE 0 END) AS null_departure_delay,
    SUM(CASE WHEN arrival_delay_min IS NULL THEN 1 ELSE 0 END) AS null_arrival_delay,
    SUM(CASE WHEN flight_status IS NULL THEN 1 ELSE 0 END) AS null_status,
    SUM(CASE WHEN actual_air_time IS NULL THEN 1 ELSE 0 END) AS null_air_time,
    SUM(CASE WHEN avg_speed IS NULL THEN 1 ELSE 0 END) AS null_avg_speed
FROM flights;
