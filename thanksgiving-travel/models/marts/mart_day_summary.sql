-- Average performance for each day of the holiday window, across every year except the pandemic.
-- No baseline comparison here, so 2025 stays in.

with days as (
    select * from {{ ref('mart_holiday_by_day') }}
    where flight_year not in {{ sql_list(var('pandemic_years')) }}
),

worst as (
    -- Which day had the lowest on-time rate in each year
    select flight_year, arg_min(days_from_thanksgiving, on_time_rate) as worst_day
    from days
    group by flight_year
)

select
    d.days_from_thanksgiving,
    any_value(d.day_name)                                  as day_name,
    count(*)                                               as years,
    round(avg(d.scheduled_flights))                        as avg_flights,
    avg(d.on_time_rate)                                    as on_time_rate,
    avg(d.cancel_rate)                                     as cancel_rate,
    avg(d.avg_arr_delay_min)                               as avg_arr_delay_min,
    count(*) filter (where w.worst_day = d.days_from_thanksgiving) as years_as_worst_day
from days as d
inner join worst as w using (flight_year)
group by d.days_from_thanksgiving
