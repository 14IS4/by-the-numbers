-- Average delay minutes per completed flight by cause: return days versus the November baseline.
-- Uses only years with a trustworthy baseline.

select
    case when period = 'baseline' then 'baseline' else 'return' end  as segment,
    count(*)                                                         as flights,
    avg(coalesce(late_aircraft_delay_min, 0))                        as late_aircraft_min,
    avg(coalesce(carrier_delay_min, 0))                              as carrier_min,
    avg(coalesce(nas_delay_min, 0))                                  as air_system_min,
    avg(coalesce(weather_delay_min, 0))                              as weather_min,
    avg(coalesce(security_delay_min, 0))                             as security_min
from {{ ref('int_flights_holiday') }}
where year(flight_date) not in {{ sql_list(var('baseline_excluded_years')) }}
    and not is_cancelled
    and (period = 'baseline' or days_from_thanksgiving between 2 and 4)
group by 1
