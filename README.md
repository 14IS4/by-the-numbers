# By the numbers

The data pipelines behind the *By the numbers* series on [horeft.is](https://horeft.is/blog). Each analysis lives in its own folder with its own ingest script, dbt project, and tests.

| Analysis | Post | Data |
|----------|------|------|
| [thanksgiving-travel](thanksgiving-travel/) | Thanksgiving travel by the numbers | BTS on-time performance, Nov and Dec 2015 to 2025 (11.6M flights) |

## Running an analysis

Requires [uv](https://docs.astral.sh/uv/). DuckDB and dbt run locally, no cloud account needed.

```bash
uv sync
uv run python thanksgiving-travel/ingest.py     # downloads raw files into thanksgiving-travel/data/ (gitignored)
cd thanksgiving-travel
uv run dbt build --profiles-dir .               # builds models and runs every test
cd .. && uv run python thanksgiving-travel/export.py   # writes chart JSON to thanksgiving-travel/exports/
```

## thanksgiving-travel

**Question:** which days and airports actually fall apart around Thanksgiving?

**Layers**

- `stg_flights`: every flight, read as text and cast in one place so bad values surface instead of failing the load
- `int_flights_holiday`: tags each flight with its offset from that year's Thanksgiving, a holiday window (Saturday before to Monday after), and a baseline (two ordinary weeks earlier in November)
- `mart_*`: the day, airport, delay cause, and baseline-check tables behind each chart

**Decisions worth knowing about**

- *On time* uses the DOT definition: arrived less than 15 minutes late, not cancelled or diverted.
- 2020 is excluded from averages. Pandemic traffic makes it a different system.
- 2025 is excluded from anything compared against the November baseline. Starting November 7, 2025, FAA-ordered flight cuts pushed daily cancellations from under 1% to 12%, so the "normal" weeks weren't normal. `mart_nov_2025_baseline_check` shows it.
- A flight's unique key includes destination and diversion status. BTS records a diverted attempt and its same-day re-flight as two rows, and a cancelled flight rerouted to another airport keeps its flight number. Both are real operations, so the test encodes them instead of deleting rows.

Source: [Bureau of Transportation Statistics, Reporting Carrier On-Time Performance](https://www.transtats.bts.gov/Fields.asp?gnoyr_VQ=FGJ).
