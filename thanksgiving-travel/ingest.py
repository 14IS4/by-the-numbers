"""Download BTS Reporting Carrier On-Time Performance files for November and December.

Source: Bureau of Transportation Statistics, TranStats prezipped monthly files.
Each zip holds one CSV with every domestic flight operated by reporting carriers that month.
Files land in data/raw/ (gitignored). Re-running skips anything already downloaded.
"""

import sys
import zipfile
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import requests

BASE_URL = (
    "https://transtats.bts.gov/PREZIP/"
    "On_Time_Reporting_Carrier_On_Time_Performance_1987_present_{year}_{month}.zip"
)
YEARS = range(2015, 2026)
MONTHS = (11, 12)
RAW_DIR = Path(__file__).parent / "data" / "raw"


def download(year: int, month: int) -> Path:
    csv_path = RAW_DIR / f"ontime_{year}_{month:02d}.csv"
    if csv_path.exists():
        return csv_path

    zip_path = RAW_DIR / f"ontime_{year}_{month:02d}.zip"
    url = BASE_URL.format(year=year, month=month)
    with requests.get(url, stream=True, timeout=120) as resp:
        resp.raise_for_status()
        with zip_path.open("wb") as f:
            for chunk in resp.iter_content(chunk_size=1 << 20):
                f.write(chunk)

    with zipfile.ZipFile(zip_path) as zf:
        csv_members = [m for m in zf.namelist() if m.lower().endswith(".csv")]
        if len(csv_members) != 1:
            raise ValueError(f"{zip_path.name}: expected 1 CSV, found {csv_members}")
        with zf.open(csv_members[0]) as src, csv_path.open("wb") as dst:
            dst.write(src.read())

    zip_path.unlink()
    return csv_path


def main() -> int:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    jobs = [(year, month) for year in YEARS for month in MONTHS]
    failures = []
    with ThreadPoolExecutor(max_workers=4) as pool:
        futures = {pool.submit(download, year, month): (year, month) for year, month in jobs}
        for future in as_completed(futures):
            year, month = futures[future]
            try:
                path = future.result()
                print(f"ok   {year}-{month:02d}  {path.stat().st_size / 1e6:,.0f} MB", flush=True)
            except (requests.RequestException, ValueError, zipfile.BadZipFile) as exc:
                failures.append((year, month))
                print(f"FAIL {year}-{month:02d}  {exc}", flush=True)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
