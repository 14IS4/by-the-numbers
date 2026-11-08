-- The 30 busiest origin airports on return days (Saturday to Monday after Thanksgiving),
-- comparing their on-time rate to the same airport's November baseline.

with flights as (
    select
        origin_airport,
        origin_city,
        is_on_time,
        case
            when period = 'baseline' then 'baseline'
            when days_from_thanksgiving between -3 and -1 then 'outbound'
            when days_from_thanksgiving between 2 and 4 then 'return'
        end as segment
    from {{ ref('int_flights_holiday') }}
    where year(flight_date) not in {{ sql_list(var('baseline_excluded_years')) }}
        and period is not null
),

by_airport as (
    select
        origin_airport,
        any_value(origin_city)                                   as origin_city,
        count(*) filter (where segment = 'return')               as return_departures,
        avg(is_on_time::int) filter (where segment = 'baseline') as baseline_on_time_rate,
        avg(is_on_time::int) filter (where segment = 'outbound') as outbound_on_time_rate,
        avg(is_on_time::int) filter (where segment = 'return')   as return_on_time_rate
    from flights
    group by origin_airport
)

select
    *,
    return_on_time_rate - baseline_on_time_rate as return_change
from by_airport
qualify row_number() over (order by return_departures desc) <= 30
