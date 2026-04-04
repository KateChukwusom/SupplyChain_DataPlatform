import logging
from collections import defaultdict

from .config import SOURCE_BUCKET, SOURCE_PREFIX, DEST_BUCKET, DEST_PREFIX, get_s3_clients
from .checkpoint import load_watermark, save_watermark
from .s3 import list_json_files, read_json_file, upload_parquet
from .transform import normalise_record, build_table

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
log = logging.getLogger(__name__)


def extract_shipments():
    source_s3, dest_s3 = get_s3_clients()

    watermark    = load_watermark(dest_s3)
    last_date    = watermark["last_processed_date"]   # e.g. "2026-03-12" or None
    failed_dates = set(watermark["failed_dates"])     # dates to retry

    json_files = list_json_files(source_s3, SOURCE_BUCKET, SOURCE_PREFIX)

    # group by date from filename
    files_by_date = defaultdict(list)
    for key in json_files:
        filename  = key.split("/")[-1]
        date_part = filename.replace("shipments_", "").replace(".json", "")
        files_by_date[date_part].append(key)

    # only process dates greater than watermark OR previously failed dates
    dates_to_process = sorted([
        date for date in files_by_date
        if (last_date is None or date > last_date) or date in failed_dates
    ])

    if not dates_to_process:
        log.info("No new dates to process. Exiting.")
        return

    log.info(f"Dates to process: {dates_to_process}")

    new_last_date = last_date   # will advance as each date succeeds
    new_failed    = set()       # track any failures this run

    for date in dates_to_process:
        files       = files_by_date[date]
        all_records = []

        for key in files:
            try:
                records = read_json_file(source_s3, SOURCE_BUCKET, key)
                for record in records:
                    all_records.append(normalise_record(record, source_file=key))
                log.info(f"Read {len(records)} records from {key}")
            except Exception as e:
                log.error(f"Failed to read {key}: {e}")
                new_failed.add(date)
                continue

        if not all_records:
            log.warning(f"No records for date {date} — skipping.")
            continue

        table    = build_table(all_records)
        dest_key = f"{DEST_PREFIX}shipments_{date}.parquet"

        try:
            upload_parquet(dest_s3, DEST_BUCKET, dest_key, table)

            # only advance watermark if this date is strictly next in sequence
            if date not in failed_dates:
                new_last_date = date

            # remove from failed if it succeeded this run
            failed_dates.discard(date)
            save_watermark(dest_s3, new_last_date, list(new_failed | failed_dates))

        except Exception as e:
            log.error(f"Failed to upload Parquet for date {date}: {e}")
            new_failed.add(date)
            save_watermark(dest_s3, new_last_date, list(new_failed | failed_dates))
            continue

    log.info("Extraction complete.")


if __name__ == "__main__":
    extract_shipments()