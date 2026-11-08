-- A flight is one airline, flight number, route, date, and scheduled departure.
-- Destination and diversion are part of the key on purpose: BTS records a diverted attempt
-- and its same-day re-flight as two rows, and a cancelled flight that gets rerouted to a
-- different airport keeps its flight number. Both are real operations, not duplicates.
select
    flight_date, airline_code, flight_number, origin_airport, dest_airport,
    scheduled_dep_hhmm, is_diverted,
    count(*) as copies
from {{ ref('stg_flights') }}
group by all
having count(*) > 1
