# This file tracks what has already been processed so that every run knows
# exactly where the last run stopped


import json
import logging
from botocore.exceptions import ClientError
from .config import CHECKPOINT_BUCKET, CHECKPOINT_KEY

#This creates a logger named after the current module
log = logging.getLogger(__name__)

# Reads the watermark file from S3 and returns it as a Python dictionary.
# If the file does not exist yet, returns a clean default state
def load_watermark(dest_s3):
    try:
        #this reaches into S3 and fetches the watermark file
        response = dest_s3.get_object(Bucket=CHECKPOINT_BUCKET, Key=CHECKPOINT_KEY)
        #S3 returns the file content as a raw byte and converts the bytes into readable string
        return json.loads(response["Body"].read().decode("utf-8"))
    except ClientError as e:
        if e.response["Error"]["Code"] == "NoSuchKey":
            log.info("No watermark found — starting fresh.")
            return {"last_processed_date": None, "failed_dates": []}
        raise


# Writes the current checkpoint back to S3 after every pipeline run.
# Records the last successfully processed date and any dates that failed
# so the next run knows exactly where to continue from.
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