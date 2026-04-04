import json
import logging
from botocore.exceptions import ClientError
from .config import CHECKPOINT_BUCKET, CHECKPOINT_KEY

log = logging.getLogger(__name__)

# watermark structure stored in S3:
# {
#   "last_processed_date": "2026-03-12",   ← last filename date fully uploaded
#   "failed_dates": ["2026-03-14"]         ← dates that failed, to retry next run
# }

def load_watermark(dest_s3) -> dict:
    try:
        response = dest_s3.get_object(Bucket=CHECKPOINT_BUCKET, Key=CHECKPOINT_KEY)
        return json.loads(response["Body"].read().decode("utf-8"))
    except ClientError as e:
        if e.response["Error"]["Code"] == "NoSuchKey":
            log.info("No watermark found — starting fresh.")
            return {"last_processed_date": None, "failed_dates": []}
        raise


def save_watermark(dest_s3, last_processed_date: str, failed_dates: list):
    payload = {
        "last_processed_date": last_processed_date,
        "failed_dates":        failed_dates
    }
    dest_s3.put_object(
        Bucket=CHECKPOINT_BUCKET,
        Key=CHECKPOINT_KEY,
        Body=json.dumps(payload).encode("utf-8")
    )
    log.info(f"Watermark saved — last processed: {last_processed_date}, failed: {failed_dates}")