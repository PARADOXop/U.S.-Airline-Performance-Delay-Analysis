-- use master DB to manage/create other databases  
use master;

-- remove old FlightAnalysis DB if present  
drop database FlightAnalysis;

-- create new FlightAnalysis database with data & log files  
CREATE DATABASE FlightAnalysis
ON PRIMARY
(
    -- main data file details  
    NAME = FlightAnalysis_Data,  
    FILENAME = 'R:\U.S.-Airline-Performance-Delay-Analysis\database\FlightAnalysis.mdf',
    SIZE = 2GB,  
    MAXSIZE = UNLIMITED,  
    FILEGROWTH = 10MB  
)
LOG ON
(
    -- log file details  
    NAME = FlightAnalysis_Log,  
    FILENAME = 'R:\U.S.-Airline-Performance-Delay-Analysis\database\FlightAnalysis.ldf',
    SIZE = 800MB,  
    MAXSIZE = 2GB,  
    FILEGROWTH = 10MB  
);

-- check the file names and locations of FlightAnalysis database  
SELECT name, physical_name AS file_location
FROM sys.master_files
WHERE database_id = DB_ID('FlightAnalysis');
