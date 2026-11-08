-- Departure performance per origin airport, holiday window versus the November baseline.

with by_period as (
    select
        year(flight_date)                                  as flight_year,
        origin_airport,
        any_value(origin_city)                             as origin_city,
        period,
        count(*)                                           as departures,
        avg(is_cancelled::int)                             as cancel_rate,
        avg(is_on_time::int)                               as on_time_rate,
        avg(dep_delay_min) filter (where not is_cancelled) as avg_dep_delay_min
    from {{ ref('int_flights_holiday') }}
    where period is not null
    group by all
)

select
    h.flight_year,
    h.origin_airport,
    h.origin_city,
    h.departures                         as holiday_departures,
    b.departures                         as baseline_departures,
    h.on_time_rate                       as holiday_on_time_rate,
    b.on_time_rate                       as baseline_on_time_rate,
    h.on_time_rate - b.on_time_rate      as on_time_change,
    h.cancel_rate                        as holiday_cancel_rate,
    b.cancel_rate                        as baseline_cancel_rate,
    h.avg_dep_delay_min                  as holiday_avg_dep_delay_min,
    b.avg_dep_delay_min                  as baseline_avg_dep_delay_min
from by_period as h
inner join by_period as b
    on h.flight_year = b.flight_year
    and h.origin_airport = b.origin_airport
    and b.period = 'baseline'
where h.period = 'holiday'
