use master;

drop database FlightAnalysis;

CREATE DATABASE FlightAnalysis
ON PRIMARY
(
    NAME = FlightAnalysis_Data,
    FILENAME = 'R:\U.S.-Airline-Performance-Delay-Analysis\database\FlightAnalysis.mdf',
    SIZE = 2GB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10MB
)
LOG ON
(
    NAME = FlightAnalysis_Log,
    FILENAME = 'R:\U.S.-Airline-Performance-Delay-Analysis\database\FlightAnalysis.ldf',
    SIZE = 800MB,
    MAXSIZE = 2GB,
    FILEGROWTH = 10MB
);

SELECT name, physical_name AS file_location
FROM sys.master_files
WHERE database_id = DB_ID('FlightAnalysis');
