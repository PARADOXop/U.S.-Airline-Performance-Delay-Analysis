# U.S.-Airline-Performance-Delay-Analysis

data link: https://drive.google.com/file/d/1_Mt-OR_IxoIy7HVkvD4bW0-fm4MRY6og/view?usp=drive_link
github link: https://github.com/PARADOXop/U.S.-Airline-Performance-Delay-Analysis
there are 3 tables in this data

1. Airlines
    Contains:

            1. IATA_CODE – Unique airline code
            
            2. AIRLINE – Airline name

2. Airports
    Contains:
            1. IATA_CODE – Unique airport code

            2. AIRPORT – Airport name

            3. CITY – City where the airport is located

            4. STATE – State where the airport is located

            5. COUNTRY – Country of the airport

            6. LATITUDE – Geographic latitude of the airport

            7. LONGITUDE – Geographic longitude of the airport

3. Flights
    Contains:

            1. Taxi Out – Time from leaving the gate to takeoff (minutes)

            2. Wheels Off – Actual time airplane lifts from the runway

            3. Scheduled Time – Planned duration of flight in minutes (scheduled departure → scheduled arrival)

            4. Elapsed Time – Actual duration of flight in minutes (actual departure → actual arrival)

            5. Air Time – Time spent in the air (minutes)

            6. Wheels On – Time when plane actually touches the runway

            7. Taxi In – Time from landing to reaching destination gate (minutes)

            8. Scheduled Arrival – Planned arrival time

            9. Arrival Time – Actual arrival time

            10. Arrival Delay – Difference between actual and scheduled arrival in minutes

            11. Diverted – 1 if diverted, else 0

            12. Cancelled – 1 if cancelled, else 0

            13. Cancellation Reason:
                    a. Carrier

                    b. Weather

                    c. National Air System

                    d. Security

            14. Air System Delay – Delay caused by air traffic system issues (minutes)

            15. Security Delay – Delay caused by security-related issues (minutes)

            16. Airline Delay – Delay caused by the airline itself (crew, maintenance, etc.) (minutes)

            17. Late Aircraft Delay – Delay caused by the aircraft arriving late from a previous flight (minutes)

            18. Weather Delay – Delay caused by weather conditions (minutes)
