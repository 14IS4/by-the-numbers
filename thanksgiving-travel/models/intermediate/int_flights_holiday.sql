-- Tags every flight with its position relative to that year's Thanksgiving.
-- Holiday window: the Saturday before through the Monday after (days -5 to +4).
-- Baseline: two ordinary weeks earlier in November (days -21 to -8), same airports and airlines.

with flights as (
    select * from {{ ref('stg_flights') }}
),

thanksgiving as (
    -- Fourth Thursday of November: first Thursday on or after Nov 1, plus three weeks
    select
        yr as flight_year,
        nov1 + cast(((4 - dayofweek(nov1)) + 7) % 7 + 21 as integer) as thanksgiving_date
    from (
        select yr, make_date(yr, 11, 1) as nov1
        from range(2015, 2026) as t(yr)
    )
)

select
    f.*,
    t.thanksgiving_date,
    f.flight_date - t.thanksgiving_date as days_from_thanksgiving,
    case
        when f.flight_date - t.thanksgiving_date between -5 and 4 then 'holiday'
        when f.flight_date - t.thanksgiving_date between -21 and -8 then 'baseline'
    end as period,
    -- On time by the DOT standard: arrived less than 15 minutes late, not cancelled or diverted
    not f.is_cancelled and not f.is_diverted and f.arr_delay_min < 15 as is_on_time
from flights as f
inner join thanksgiving as t
    on year(f.flight_date) = t.flight_year
