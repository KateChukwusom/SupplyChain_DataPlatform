import io
import json
import logging
import time
import pyarrow.parquet as pq
from botocore.exceptions import ClientError
from .config import MAX_RETRIES, RETRY_BACKOFF

log = logging.getLogger(__name__)


def list_json_files(source_s3, bucket, prefix) -> list:
    paginator = source_s3.get_paginator("list_objects_v2")
    files = []
    for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
        for obj in page.get("Contents", []):
            if obj["Key"].endswith(".json"):
                files.append(obj["Key"])
    return sorted(files)


def read_json_file(source_s3, bucket, key) -> list:
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = source_s3.get_object(Bucket=bucket, Key=key)
            content  = response["Body"].read().decode("utf-8")
            parsed   = json.loads(content)
            if isinstance(parsed, dict):
                return [parsed]
            elif isinstance(parsed, list):
                return parsed
            else:
                raise ValueError(f"Unexpected JSON structure in {key}")
        except ClientError as e:
            log.warning(f"Attempt {attempt}/{MAX_RETRIES} failed reading {key}: {e}")
            if attempt < MAX_RETRIES:
                time.sleep(RETRY_BACKOFF * attempt)
            else:
                raise


def upload_parquet(dest_s3, dest_bucket, dest_key, table):
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            buf = io.BytesIO()
            pq.write_table(table, buf, compression="snappy")
            buf.seek(0)
            dest_s3.put_object(Bucket=dest_bucket, Key=dest_key, Body=buf.getvalue())
            log.info(f"Uploaded → s3://{dest_bucket}/{dest_key} ({table.num_rows} records)")
            return
        except ClientError as e:
            log.warning(f"Upload attempt {attempt}/{MAX_RETRIES} failed for {dest_key}: {e}")
            if attempt < MAX_RETRIES:
                time.sleep(RETRY_BACKOFF * attempt)
            else:
                raise