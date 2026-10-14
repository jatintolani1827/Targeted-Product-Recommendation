from __future__ import annotations

import sys
from pathlib import Path

from apscheduler.schedulers.blocking import BlockingScheduler

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.append(str(PROJECT_ROOT))

from ml.full_pipeline import run_full_pipeline  # noqa: E402


def run_nightly_jobs() -> None:
    run_full_pipeline()


def main() -> None:
    scheduler = BlockingScheduler(timezone="Asia/Kolkata")
    scheduler.add_job(run_nightly_jobs, "cron", hour=2, minute=0, id="nightly-etl-ml")
    scheduler.start()


if __name__ == "__main__":
    main()
