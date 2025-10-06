USE FlightAnalysis;

-- quick sample view to ensure data looks right
SELECT TOP 10 *
FROM flights;

-- **********************************
-- Data Overview and Basic Distribution
-- **********************************

-- 1) share of flights that are cancelled or diverted
SELECT
    CAST(ROUND(SUM(CASE WHEN cancelled = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(1), 2) AS FLOAT) AS percentage_cancelled_flights,
    CAST(ROUND(SUM(CASE WHEN diverted = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(1), 2) AS FLOAT) AS percentage_diverted_flights
FROM flights;
-- note: using 100.0 forces decimal math; ROUND(…,2) for 2 decimals

-- 2) cancellation reasons snapshot (what labels exist)
SELECT DISTINCT cancellation_reason_desc
FROM flights;

-- cancellation breakdown among only cancelled flights
SELECT 
    COUNT(1) AS cancelled_flight_count, 
    SUM(CASE WHEN cancellation_reason_desc = 'Airline' THEN 1 ELSE 0 END) * 100.0 / COUNT(1) AS percent_airline,
    SUM(CASE WHEN cancellation_reason_desc = 'Weather' THEN 1 ELSE 0 END) * 100.0 / COUNT(1) AS percent_weather,
    SUM(CASE WHEN cancellation_reason_desc = 'Security' THEN 1 ELSE 0 END) * 100.0 / COUNT(1) AS percent_security,
    SUM(CASE WHEN cancellation_reason_desc = 'Air System' THEN 1 ELSE 0 END) * 100.0 / COUNT(1) AS percent_air_system
FROM flights
WHERE cancelled = 1;

-- 3) min/max/avg for departure vs arrival delays (completed flights only)
SELECT 
    MIN(departure_delay_min) AS min_departure_delay,
    MAX(departure_delay_min) AS max_departure_delay,
    AVG(departure_delay_min) AS avg_departure_delay,
    MIN(arrival_delay_min) AS min_arrival_delay,
    MAX(arrival_delay_min) AS max_arrival_delay,
    AVG(arrival_delay_min) AS avg_arrival_delay
FROM flights
WHERE cancelled = 0 AND diverted = 0;

-- 4) total hours by delay type (sum minutes/60) for completed flights
SELECT 
    COUNT(1) AS total_flights, 
    CAST(ROUND(SUM(ISNULL(air_system_delay, 0)) / 60.0, 2) AS FLOAT) AS total_air_system_delay_hours,
    CAST(ROUND(SUM(ISNULL(security_delay, 0)) / 60.0, 2) AS FLOAT) AS total_security_delay_hours,
    CAST(ROUND(SUM(ISNULL(airline_delay, 0)) / 60.0, 2) AS FLOAT) AS total_airline_delay_hours,
    CAST(ROUND(SUM(ISNULL(late_aircraft_delay, 0)) / 60.0, 2) AS FLOAT) AS total_late_aircraft_delay_hours,
    CAST(ROUND(SUM(ISNULL(weather_delay, 0)) / 60.0, 2) AS FLOAT) AS total_weather_delay_hours
FROM flights
WHERE flight_status = 'Completed';

-- **********************************
-- Advanced Exploratory Data Analysis
-- **********************************

-- 1. Delay Dynamics (Beyond Simple Averages)

-- a) cross-tab of dep delay bucket vs arr delay bucket + percent of total
SELECT 
    departure_delay_cat,
    arrival_delay_cat,
    COUNT(*) AS flight_count,
    CAST(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS FLOAT) AS percent_of_total
FROM flights
WHERE cancelled = 0 AND diverted = 0
GROUP BY departure_delay_cat, arrival_delay_cat
ORDER BY departure_delay_cat, arrival_delay_cat;

-- b) flights that left late but still arrived on time (made up time)
SELECT 
    COUNT(*) AS flights_made_up_time,
    CAST(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM flights WHERE cancelled = 0 AND diverted = 0), 2) AS FLOAT) AS percent_of_total,
    AVG(departure_delay_min) AS avg_departure_delay,
    AVG(arrival_delay_min) AS avg_arrival_delay,
    MIN(departure_delay_min) AS min_departure_delay,
    MAX(departure_delay_min) AS max_departure_delay
FROM flights
WHERE cancelled = 0 
  AND diverted = 0
  AND departure_delay_min > 0
  AND arrival_delay_min <= 0;

-- c) weather delay by distance bands (short/medium/long haul)
SELECT 
    CASE 
        WHEN distance < 500 THEN 'Short-haul'
        WHEN distance BETWEEN 500 AND 1500 THEN 'Medium-haul'
        ELSE 'Long-haul'
    END AS flight_type,
    COUNT(*) AS total_flights,
    CAST(ROUND(AVG(weather_delay), 2) AS FLOAT) AS avg_weather_delay,
    CAST(ROUND(SUM(weather_delay) / 60.0, 2) AS FLOAT) AS total_weather_delay_hours
FROM flights
WHERE cancelled = 0 
  AND diverted = 0
  AND weather_delay IS NOT NULL
GROUP BY 
    CASE 
        WHEN distance < 500 THEN 'Short-haul'
        WHEN distance BETWEEN 500 AND 1500 THEN 'Medium-haul'
        ELSE 'Long-haul'
    END;

-- 2. Airline-Level Deep Dives

-- on-time arrivals (<= 15 min late) by airline with percentage
SELECT top 3
    f.airline_code,
    a.airline_name AS airline_name,
    COUNT(*) AS total_flights,
    SUM(CASE WHEN f.arrival_delay_min <= 15 THEN 1 ELSE 0 END) AS on_time_flights,
    CAST(ROUND(SUM(CASE WHEN f.arrival_delay_min <= 15 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS FLOAT) AS punctuality_pct
FROM flights f
JOIN airlines a
    ON f.airline_code = a.airline_code
WHERE f.cancelled = 0 AND f.diverted = 0
GROUP BY f.airline_code, a.airline_name
ORDER BY punctuality_pct DESC;

-- cancellation mix per airline (percent within that airline's cancellations)
SELECT top 3
    a.airline_name,
    f.cancellation_reason_desc,
    COUNT(*) AS cancelled_flights,
    CAST(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY a.airline_name), 2) AS FLOAT) AS pct_of_airline_cancellations
FROM flights f
JOIN airlines a
    ON f.airline_code = a.airline_code
WHERE f.cancelled = 1
GROUP BY a.airline_name, f.cancellation_reason_desc
ORDER BY a.airline_name, cancelled_flights DESC;

-- simple departure punctuality index per airline (<= 0 = on time or early)
SELECT top 3
    a.airline_name,
    COUNT(*) AS total_flights,
    SUM(CASE WHEN f.departure_delay_min <= 0 THEN 1 ELSE 0 END) AS on_time_flights,
    CAST(ROUND(SUM(CASE WHEN f.departure_delay_min <= 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS FLOAT) AS punctuality_index
FROM flights f
JOIN airlines a
    ON f.airline_code = a.airline_code
WHERE f.cancelled = 0 AND f.diverted = 0
GROUP BY a.airline_name
ORDER BY punctuality_index DESC;

-- 3. Airport-Level Advanced Insights

-- average departure/arrival delay by origin airport (completed+cancel excluded)
SELECT 
    ap.airport_name,
    f.origin_airport,
    COUNT(*) AS total_flights,
    AVG(f.departure_delay_min) AS avg_departure_delay,
    AVG(f.arrival_delay_min) AS avg_arrival_delay
FROM flights f
JOIN airports ap
    ON f.origin_airport = ap.IATA_code
WHERE f.cancelled = 0
GROUP BY ap.airport_name, f.origin_airport
ORDER BY avg_departure_delay DESC;

-- airport departures volume and their average delays
SELECT 
    ap.airport_name,
    f.origin_airport,
    COUNT(*) AS total_departures,
    AVG(f.departure_delay_min) AS avg_dep_delay,
    AVG(f.arrival_delay_min) AS avg_arr_delay
FROM flights f
JOIN airports ap
    ON f.origin_airport = ap.IATA_code
WHERE f.cancelled = 0
GROUP BY ap.airport_name, f.origin_airport
ORDER BY total_departures DESC;

-- cancellation clustering by origin and reason (share within that origin)
SELECT 
    ap.airport_name,
    f.origin_airport,
    COUNT(*) AS total_flights,
    SUM(CASE WHEN f.cancelled = 1 THEN 1 ELSE 0 END) AS cancelled_flights,
    CAST(ROUND(SUM(CASE WHEN f.cancelled = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS FLOAT) AS pct_cancelled,
    f.cancellation_reason_desc
FROM flights f
JOIN airports ap
    ON f.origin_airport = ap.IATA_code
WHERE f.cancelled = 1
GROUP BY ap.airport_name, f.origin_airport, f.cancellation_reason_desc
ORDER BY pct_cancelled DESC;
