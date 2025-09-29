use  FlightAnalysis;


--1. check if all rows are loaded up
select count(*)
from airlines;

select count(*)
from airports;

select count(*)
from flights;


--2. values sanity checks

-- years available
SELECT DISTINCT year FROM flights ORDER BY year;

-- months and days should be within calendar limits
SELECT MIN(month) AS min_month, MAX(month) AS max_month,
       MIN(day) AS min_day, MAX(day) AS max_day
FROM flights;

-- departure delay distribution
SELECT MIN(departure_delay) AS min_delay, MAX(departure_delay) AS max_delay
FROM flights;


-- check for foreign keys 
-- any flights referencing an unknown airline?
SELECT DISTINCT airline_code
FROM flights
WHERE airline_code NOT IN (SELECT airline_code FROM airlines);

-- any unknown origin airports?
SELECT DISTINCT origin_airport
FROM flights
WHERE origin_airport NOT IN (SELECT IATA_code FROM airports);
