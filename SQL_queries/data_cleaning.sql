
USE FlightAnalysis;

-- Step 1: Set SIMPLE recovery for minimal logging

ALTER DATABASE FlightAnalysis SET RECOVERY SIMPLE;


-- Step 2: Add datetime columns if they don't exist

ALTER TABLE flights
ADD scheduled_departure_dttime DATETIME NULL,
    departure_time_dttime DATETIME NULL,
    wheels_off_dttime DATETIME NULL,
    wheels_on_dttime DATETIME NULL,
    arrival_time_dttime DATETIME NULL,
    scheduled_arrival_dttime DATETIME NULL;

SET NOCOUNT ON;

DECLARE @BatchSize INT = 500000;

WHILE 1 = 1
BEGIN
    ;WITH cte AS (
        SELECT TOP (@BatchSize) *
        FROM flights
        WHERE scheduled_departure_dttime IS NULL
        ORDER BY year, month, day, flight_number
    )
    UPDATE cte
    SET scheduled_departure_dttime = DATEADD(MINUTE,
                                CAST(LEFT(scheduled_departure,2) AS INT) * 60 +
                                CAST(RIGHT(scheduled_departure,2) AS INT),
                                CAST(CONCAT(year,'-',month,'-',day,' 00:00:00') AS DATETIME)),

        departure_time_dttime = CASE WHEN departure_time IS NOT NULL
             THEN DATEADD(MINUTE,
                 CAST(LEFT(departure_time,2) AS INT) * 60 +
                 CAST(RIGHT(departure_time,2) AS INT),
                 CAST(CONCAT(year,'-',month,'-',day,' 00:00:00') AS DATETIME)) END,

        wheels_off_dttime = CASE WHEN wheels_off IS NOT NULL
             THEN DATEADD(MINUTE,
                 CAST(LEFT(wheels_off,2) AS INT) * 60 +
                 CAST(RIGHT(wheels_off,2) AS INT),
                 CAST(CONCAT(year,'-',month,'-',day,' 00:00:00') AS DATETIME)) END,

        wheels_on_dttime = CASE WHEN wheels_on IS NOT NULL
             THEN DATEADD(MINUTE,
                 CAST(LEFT(wheels_on,2) AS INT) * 60 +
                 CAST(RIGHT(wheels_on,2) AS INT),
                 CAST(CONCAT(year,'-',month,'-',day,' 00:00:00') AS DATETIME)) END,

        arrival_time_dttime = CASE WHEN arrival_time IS NOT NULL
             THEN DATEADD(MINUTE,
                 CAST(LEFT(arrival_time,2) AS INT) * 60 +
                 CAST(RIGHT(arrival_time,2) AS INT),
                 CAST(CONCAT(year,'-',month,'-',day,' 00:00:00') AS DATETIME)) END,

        scheduled_arrival_dttime = CASE WHEN scheduled_arrival IS NOT NULL
             THEN DATEADD(MINUTE,
                 CAST(LEFT(scheduled_arrival,2) AS INT) * 60 +
                 CAST(RIGHT(scheduled_arrival,2) AS INT),
                 CAST(CONCAT(year,'-',month,'-',day,' 00:00:00') AS DATETIME)) END;

    -- Exit loop if no rows updated
    IF @@ROWCOUNT = 0 BREAK;

    -- Free log after each batch
    CHECKPOINT;
END




DBCC SHRINKFILE (FlightAnalysis_Log, 1);

ALTER DATABASE FlightAnalysis SET RECOVERY FULL;

ALTER TABLE flights
DROP COLUMN scheduled_departure,
            departure_time,
            scheduled_arrival,
            wheels_off,
            wheels_on,
            arrival_time;

select top 10 *
from flights;

-- 2. handle columns missing values.
-- can also create a single table/view by joining all the tables


SELECT 
    COUNT(*) AS total_rows,

    SUM(CASE WHEN year IS NULL THEN 1 ELSE 0 END) AS null_year,
    SUM(CASE WHEN month IS NULL THEN 1 ELSE 0 END) AS null_month,
    SUM(CASE WHEN day IS NULL THEN 1 ELSE 0 END) AS null_day,
    SUM(CASE WHEN day_of_week IS NULL THEN 1 ELSE 0 END) AS null_day_of_week,

    SUM(CASE WHEN airline_code IS NULL THEN 1 ELSE 0 END) AS null_airline_code,
    SUM(CASE WHEN flight_number IS NULL THEN 1 ELSE 0 END) AS null_flight_number,
    SUM(CASE WHEN tail_number IS NULL THEN 1 ELSE 0 END) AS null_tail_number,

    SUM(CASE WHEN origin_airport IS NULL THEN 1 ELSE 0 END) AS null_origin_airport,
    SUM(CASE WHEN destination_airport IS NULL THEN 1 ELSE 0 END) AS null_destination_airport,
    SUM(CASE WHEN taxi_out IS NULL THEN 1 ELSE 0 END) AS null_taxi_out,
    SUM(CASE WHEN scheduled_time IS NULL THEN 1 ELSE 0 END) AS null_scheduled_time,
    SUM(CASE WHEN elapsed_time IS NULL THEN 1 ELSE 0 END) AS null_elapsed_time,
    SUM(CASE WHEN air_time IS NULL THEN 1 ELSE 0 END) AS null_air_time,
    SUM(CASE WHEN distance IS NULL THEN 1 ELSE 0 END) AS null_distance,
    SUM(CASE WHEN taxi_in IS NULL THEN 1 ELSE 0 END) AS null_taxi_in,

    SUM(CASE WHEN diverted IS NULL THEN 1 ELSE 0 END) AS null_diverted,
    SUM(CASE WHEN cancelled IS NULL THEN 1 ELSE 0 END) AS null_cancelled,
    SUM(CASE WHEN cancellation_reason IS NULL THEN 1 ELSE 0 END) AS null_cancellation_reason,

    SUM(CASE WHEN air_system_delay IS NULL THEN 1 ELSE 0 END) AS null_air_system_delay,
    SUM(CASE WHEN security_delay IS NULL THEN 1 ELSE 0 END) AS null_security_delay,
    SUM(CASE WHEN airline_delay IS NULL THEN 1 ELSE 0 END) AS null_airline_delay,
    SUM(CASE WHEN late_aircraft_delay IS NULL THEN 1 ELSE 0 END) AS null_late_aircraft_delay,
    SUM(CASE WHEN weather_delay IS NULL THEN 1 ELSE 0 END) AS null_weather_delay,

    SUM(CASE WHEN scheduled_departure_dttime IS NULL THEN 1 ELSE 0 END) AS null_scheduled_departure_dttime,
    SUM(CASE WHEN departure_time_dttime IS NULL THEN 1 ELSE 0 END) AS null_departure_time_dttime,
    SUM(CASE WHEN wheels_off_dttime IS NULL THEN 1 ELSE 0 END) AS null_wheels_off_dttime,
    SUM(CASE WHEN wheels_on_dttime IS NULL THEN 1 ELSE 0 END) AS null_wheels_on_dttime,
    SUM(CASE WHEN arrival_time_dttime IS NULL THEN 1 ELSE 0 END) AS null_arrival_time_dttime,
    SUM(CASE WHEN scheduled_arrival_dttime IS NULL THEN 1 ELSE 0 END) AS null_scheduled_arrival_dttime
FROM flights;

-- Dropping rows where flight_number is null
DELETE FROM flights
WHERE flight_number IS NULL;

-- Null analysis for key flight event times
SELECT 
    'departure_time_dttime' AS column_name,
    COUNT(*) AS total_nulls,
    SUM(CASE WHEN cancelled = 1 THEN 1 ELSE 0 END) AS due_to_cancellation,
    SUM(CASE WHEN diverted = 1 THEN 1 ELSE 0 END) AS due_to_diversion,
    SUM(CASE WHEN cancelled = 0 AND diverted = 0 THEN 1 ELSE 0 END) AS other_reason
FROM flights
WHERE departure_time_dttime IS NULL

UNION ALL

SELECT 
    'wheels_off_dttime',
    COUNT(*),
    SUM(CASE WHEN cancelled = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN diverted = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN cancelled = 0 AND diverted = 0 THEN 1 ELSE 0 END)
FROM flights
WHERE wheels_off_dttime IS NULL

UNION ALL

SELECT 
    'wheels_on_dttime',
    COUNT(*),
    SUM(CASE WHEN cancelled = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN diverted = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN cancelled = 0 AND diverted = 0 THEN 1 ELSE 0 END)
FROM flights
WHERE wheels_on_dttime IS NULL

UNION ALL

SELECT 
    'arrival_time_dttime',
    COUNT(*),
    SUM(CASE WHEN cancelled = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN diverted = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN cancelled = 0 AND diverted = 0 THEN 1 ELSE 0 END)
FROM flights
WHERE arrival_time_dttime IS NULL;




-- finding what reasons affects which delay

select top 50 DEPARTURE_DELAY, ARRIVAL_DELAY, AIR_SYSTEM_DELAY, AIRLINE_DELAY, SECURITY_DELAY, LATE_AIRCRAFT_DELAY, WEATHER_DELAY
from flights;

-- delay and there type wont sum up everytime. because when delay is happening system only records high priority once so there will be error in here.

-- drop year, month and day columns

ALTER TABLE flights
DROP COLUMN year, month, day;


