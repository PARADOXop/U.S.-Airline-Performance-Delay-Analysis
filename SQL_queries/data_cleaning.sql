
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

DECLARE @BatchSize INT = 50000;

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




SELECT TOP 10
    year, month, day,
    scheduled_departure, scheduled_departure_dttime,
    departure_time, departure_time_dttime,
    wheels_off, wheels_off_dttime,
    wheels_on, wheels_on_dttime,
    arrival_time, arrival_time_dttime,
    scheduled_arrival, scheduled_arrival_dttime
FROM flights;


DBCC SHRINKFILE (FlightAnalysis_Log, 1);

ALTER DATABASE FlightAnalysis SET RECOVERY FULL;



SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN scheduled_departure_dttime IS NULL THEN 1 ELSE 0 END) AS null_scheduled_departure,
    SUM(CASE WHEN departure_time_dttime IS NULL THEN 1 ELSE 0 END) AS null_departure_time,
    SUM(CASE WHEN wheels_off_dttime IS NULL THEN 1 ELSE 0 END) AS null_wheels_off,
    SUM(CASE WHEN wheels_on_dttime IS NULL THEN 1 ELSE 0 END) AS null_wheels_on,
    SUM(CASE WHEN arrival_time_dttime IS NULL THEN 1 ELSE 0 END) AS null_arrival_time,
    SUM(CASE WHEN scheduled_arrival_dttime IS NULL THEN 1 ELSE 0 END) AS null_scheduled_arrival,
    SUM(CASE WHEN cancellation_reason IS NULL THEN 1 ELSE 0 END) AS null_cancellation_reason
FROM flights;

-- 2. handle columns missing values.
-- can also create a single table/view by joining all the tables