-- Daily cancellation rate in November 2025 next to the average for the same date in normal years.
-- Shows why the 2025 baseline weeks can't be trusted.

with daily as (
    select
        flight_date,
        year(flight_date)                                  as flight_year,
        day(flight_date)                                   as day_of_month,
        avg(is_cancelled::int)                             as cancel_rate,
        -- cancellation_code is null on completed flights, so this averages over cancellations only
        avg((cancellation_code = 'C')::int)                as air_system_share_of_cancels
    from {{ ref('stg_flights') }}
    where month(flight_date) = 11
    group by all
)

select
    d.flight_date,
    d.day_of_month,
    d.cancel_rate,
    d.air_system_share_of_cancels,
    n.normal_cancel_rate
from daily as d
inner join (
    select day_of_month, avg(cancel_rate) as normal_cancel_rate
    from daily
    where flight_year not in {{ sql_list(var('baseline_excluded_years')) }}
    group by day_of_month
) as n using (day_of_month)
where d.flight_year = 2025
