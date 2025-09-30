use  FlightAnalysis;

drop table if exists flights;
drop table if exists airlines;

drop table if exists airports;


CREATE TABLE airlines (
    airline_code CHAR(2) PRIMARY KEY,       -- NK, AA, etc.
    airline_name VARCHAR(100) NOT NULL
);


CREATE TABLE airports (
    IATA_code CHAR(3) PRIMARY KEY,          -- e.g. MSP
    airport_name VARCHAR(300) NOT NULL,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6)
);



CREATE TABLE flights (
    year SMALLINT,
    month TINYINT,
    day TINYINT,
    day_of_week TINYINT,

    airline_code CHAR(2) NOT NULL,          -- foreign key
    flight_number INT,
    tail_number VARCHAR(10),

    origin_airport CHAR(300) NOT NULL,        -- 3-letter IATA code
    destination_airport CHAR(300) NOT NULL,   -- 3-letter IATA code

    scheduled_departure CHAR(4),            -- HHMM
    departure_time CHAR(4) NULL,
    departure_delay SMALLINT NULL,
    taxi_out SMALLINT NULL,
    wheels_off CHAR(4) NULL,

    scheduled_time SMALLINT,
    elapsed_time SMALLINT NULL,
    air_time SMALLINT NULL,
    distance SMALLINT,

    wheels_on CHAR(4) NULL,
    taxi_in SMALLINT NULL,

    scheduled_arrival CHAR(4),
    arrival_time CHAR(4) NULL,
    arrival_delay SMALLINT NULL,

    diverted BIT,
    cancelled BIT,
    cancellation_reason CHAR(1) NULL,

    air_system_delay SMALLINT NULL,
    security_delay SMALLINT NULL,
    airline_delay SMALLINT NULL,
    late_aircraft_delay SMALLINT NULL,
    weather_delay SMALLINT NULL,

    -- foreign key
    CONSTRAINT FK_Flights_Airline FOREIGN KEY (airline_code)
        REFERENCES airlines(airline_code)
);


-- lets insert into tables on
-- we use bulk to insert in bulk

BULK INSERT airlines
FROM 'R:\U.S.-Airline-Performance-Delay-Analysis\data\airlines.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    CODEPAGE = '65001'
);



BULK INSERT airports
FROM 'R:\U.S.-Airline-Performance-Delay-Analysis\data\airports.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    CODEPAGE = '65001'
);


BULK INSERT flights
FROM 'R:\U.S.-Airline-Performance-Delay-Analysis\data\flights.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    CODEPAGE = '65001',
    KEEPNULLS
);




select *
from airports;

select *
from airlines;


select *
from flights;