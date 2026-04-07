import boto3
import json
import io
import logging
import pyarrow as pa
import pyarrow.parquet as pq
from datetime import datetime, timezone
import gspread
from google.oauth2.service_account import Credentials

#config
SHEET_ID          = "1OWHfaQP_wEJxw8xQ1gz2bPZdiMRDjD2eB63grcaJTEg"
DEST_BUCKET       = "raw-supplychain360-dekatede"
DEST_KEY          = "raw/stores/stores.parquet"
SSM_SERVICE_ACCT  = "/supplychain360/google/service_account_json"
SSM_DATALAKE_KEY  = "/supplychain360/airbyte/datalake_access_key_id"
SSM_DATALAKE_SEC  = "/supplychain360/airbyte/datalake_secret_access_key"

SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets.readonly",
    "https://www.googleapis.com/auth/drive.readonly",
]

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
log = logging.getLogger(__name__)


SCHEMA = pa.schema([
    pa.field("STORE_ID",        pa.string()),
    pa.field("STORE_NAME",      pa.string()),
    pa.field("CITY",            pa.string()),
    pa.field("STATE",           pa.string()),
    pa.field("REGION",          pa.string()),
    pa.field("STORE_OPEN_DATE", pa.string()),
    pa.field("LOADED_AT",       pa.timestamp("us", tz="UTC")),
])


def get_ssm_value(ssm, name: str, decrypt: bool = True) -> str:
    return ssm.get_parameter(Name=name, WithDecryption=decrypt)["Parameter"]["Value"]


from airflow.providers.amazon.aws.hooks.base_aws import AwsBaseHook

def get_clients():
    """This connects to AWS SSM via Airflow, authenticates with Google Sheets then builds an S3 client"""
    hook = AwsBaseHook(aws_conn_id="aws_ssm", client_type="ssm", region_name="eu-west-1")
    ssm = hook.get_client_type()

    def get(name):
        return ssm.get_parameter(Name=name, WithDecryption=True)["Parameter"]["Value"]

    # google credentials
    service_account_info = json.loads(get(SSM_SERVICE_ACCT))
    creds = Credentials.from_service_account_info(service_account_info, scopes=SCOPES)
    gc = gspread.authorize(creds)

    # s3 client
    s3 = boto3.client(
        "s3",
        aws_access_key_id=get(SSM_DATALAKE_KEY),
        aws_secret_access_key=get(SSM_DATALAKE_SEC),
        region_name="eu-west-1"
    )

    return gc, s3

def extract_stores():
    """This reads the google sheets, normalizes the rows, builds a parquet table and uploads to s3"""
    gc, s3 = get_clients()

    # read sheet
    sheet   = gc.open_by_key(SHEET_ID).sheet1
    records = sheet.get_all_records()
    log.info(f"Read {len(records)} rows from Google Sheets.")

    # normalise
    loaded_at = datetime.now(timezone.utc)
    rows = []
    for record in records:
        rows.append({
            "STORE_ID":        str(record.get("store_id", "") or ""),
            "STORE_NAME":      str(record.get("store_name", "") or ""),
            "CITY":            str(record.get("city", "") or ""),
            "STATE":           str(record.get("state", "") or ""),
            "REGION":          str(record.get("region", "") or ""),
            "STORE_OPEN_DATE": str(record.get("store_open_date", "") or ""),
            "LOADED_AT":       loaded_at,
        })

    # build parquet
    table = pa.Table.from_pylist(rows, schema=SCHEMA)

    # upload to s3 — overwrites same key every run (full refresh, 801 rows is tiny)
    buf = io.BytesIO()
    pq.write_table(table, buf, compression="snappy")
    buf.seek(0)
    s3.put_object(Bucket=DEST_BUCKET, Key=DEST_KEY, Body=buf.getvalue())
    log.info(f"Uploaded → s3://{DEST_BUCKET}/{DEST_KEY} ({table.num_rows} rows)")


if __name__ == "__main__":
    extract_stores()