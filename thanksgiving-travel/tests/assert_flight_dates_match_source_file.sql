-- Each monthly file should only contain flights from that month.
select source_file, flight_date
from {{ ref('stg_flights') }}
where strftime(flight_date, 'ontime_%Y_%m') <> source_file
