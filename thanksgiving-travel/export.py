"""Export the marts as small JSON files for the charts on horeft.is.

Usage: uv run python thanksgiving-travel/export.py [output_dir]
Defaults to thanksgiving-travel/exports/. Rates are exported as percentages rounded to one decimal.
"""

import json
import sys
from pathlib import Path

import duckdb

PROJECT_DIR = Path(__file__).parent
DB_PATH = PROJECT_DIR / "data" / "thanksgiving_travel.duckdb"

QUERIES = {
    "day-summary": """
        select days_from_thanksgiving as day_offset, day_name as day,
               avg_flights::int as flights,
               round(on_time_rate * 100, 1) as on_time_pct,
               round(cancel_rate * 100, 2) as cancel_pct,
               round(avg_arr_delay_min, 1) as avg_delay_min,
               years_as_worst_day as worst_day_years, years
        from mart_day_summary order by day_offset
    """,
    "delay-causes": """
        select segment,
               round(late_aircraft_min, 2) as late_aircraft,
               round(carrier_min, 2) as airline,
               round(air_system_min, 2) as air_system,
               round(weather_min, 2) as weather
        from mart_delay_causes order by segment desc
    """,
    "airport-return-drop": """
        select origin_airport as airport, origin_city as city,
               round(baseline_on_time_rate * 100, 1) as baseline_pct,
               round(return_on_time_rate * 100, 1) as return_pct,
               round(return_change * 100, 1) as change_pts
        from mart_airport_return_drop order by change_pts
    """,
    "detroit-vs-vegas": """
        select flight_year as year,
               round(max(return_on_time_rate) filter (where origin_airport = 'DTW') * 100, 1) as dtw_pct,
               round(max(return_on_time_rate) filter (where origin_airport = 'LAS') * 100, 1) as las_pct
        from mart_airport_return_by_year
        where origin_airport in ('DTW', 'LAS')
        group by flight_year order by flight_year
    """,
    "nov-2025-cancellations": """
        select strftime(flight_date, '%Y-%m-%d') as date,
               round(cancel_rate * 100, 2) as cancel_pct,
               round(air_system_share_of_cancels * 100, 1) as air_system_share_pct,
               round(normal_cancel_rate * 100, 2) as normal_cancel_pct
        from mart_nov_2025_baseline_check order by flight_date
    """,
}


def main() -> int:
    out_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else PROJECT_DIR / "exports"
    out_dir.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(DB_PATH), read_only=True)
    for name, sql in QUERIES.items():
        rel = con.sql(sql)
        rows = [dict(zip(rel.columns, row)) for row in rel.fetchall()]
        if not rows:
            print(f"FAIL {name}: no rows", file=sys.stderr)
            return 1
        (out_dir / f"{name}.json").write_text(json.dumps(rows, indent=2) + "\n")
        print(f"ok   {name}.json  {len(rows)} rows")
    return 0


if __name__ == "__main__":
    sys.exit(main())
