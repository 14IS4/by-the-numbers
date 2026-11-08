-- Raw on-time rate on return days for each airport and year. No baseline, so every year is usable.

select
    year(flight_date)        as flight_year,
    origin_airport,
    count(*)                 as departures,
    avg(is_on_time::int)     as return_on_time_rate
from {{ ref('int_flights_holiday') }}
where days_from_thanksgiving between 2 and 4
group by all
