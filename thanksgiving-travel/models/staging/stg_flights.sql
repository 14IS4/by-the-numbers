-- One row per scheduled domestic flight from the BTS on-time files.
-- Everything is read as text first so bad values surface here instead of failing the load.

with raw as (
    select *
    from read_csv(
        '{{ var("raw_glob") }}',
        header = true,
        all_varchar = true,
        union_by_name = true,
        filename = true
    )
)

select
    cast(FlightDate as date)                         as flight_date,
    Reporting_Airline                                as airline_code,
    nullif(Tail_Number, '')                          as tail_number,
    Flight_Number_Reporting_Airline                  as flight_number,
    Origin                                           as origin_airport,
    OriginCityName                                   as origin_city,
    OriginState                                      as origin_state,
    Dest                                             as dest_airport,
    DestCityName                                     as dest_city,
    -- Scheduled local times arrive as hhmm text, and BTS uses 2400 for midnight
    lpad(CRSDepTime, 4, '0')                         as scheduled_dep_hhmm,
    DepTimeBlk                                       as dep_time_block,
    try_cast(DepDelay as double)                     as dep_delay_min,
    try_cast(ArrDelay as double)                     as arr_delay_min,
    try_cast(Cancelled as double) = 1                as is_cancelled,
    nullif(CancellationCode, '')                     as cancellation_code,
    try_cast(Diverted as double) = 1                 as is_diverted,
    try_cast(CarrierDelay as double)                 as carrier_delay_min,
    try_cast(WeatherDelay as double)                 as weather_delay_min,
    try_cast(NASDelay as double)                     as nas_delay_min,
    try_cast(SecurityDelay as double)                as security_delay_min,
    try_cast(LateAircraftDelay as double)            as late_aircraft_delay_min,
    regexp_extract(filename, 'ontime_\d{4}_\d{2}')   as source_file
from raw
