-- Daily performance across the holiday window, one row per year and day offset.

select
    year(flight_date)                                    as flight_year,
    days_from_thanksgiving,
    dayname(flight_date)                                 as day_name,
    count(*)                                             as scheduled_flights,
    avg(is_cancelled::int)                               as cancel_rate,
    avg(is_on_time::int)                                 as on_time_rate,
    avg(arr_delay_min) filter (where not is_cancelled)   as avg_arr_delay_min
from {{ ref('int_flights_holiday') }}
where period = 'holiday'
group by all
