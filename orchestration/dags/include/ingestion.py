

# dags/helpers/ingestion_tasks.py
#
# This file is the bridge between the existing ingestion code
# and Airflow. It does not rewrite the ingestion logic  it wraps it.
#
# Each function here is what gets passed to a PythonOperator in the DAG.
# Its job is:
#  Push the S3 path to XCom so the Snowflake task knows where to read from

import logging
from include.slack import send_slack_message

# Import existing ingestion modules
from ingestion.shipments.extract import extract_shipments 
from ingestion.stores.extract_stores import extract_stores 
from ingestion.shipments.config import DEST_BUCKET, DEST_PREFIX

log = logging.getLogger(__name__)




def ingest_s3_file(**context):
    ti = context["ti"]
    
    log.info("Starting S3 file ingestion")
    extract_shipments()
    log.info("S3 file ingestion complete")

    s3_path = f"s3://{DEST_BUCKET}/{DEST_PREFIX}"
    ti.xcom_push(key="s3_path", value=s3_path)

    send_slack_message("Alert: *S3 file ingestion complete*")


def ingest_google_sheets(**context):
    ti = context["ti"]

    log.info("starting google sheets file ingestion")
    extract_stores()
    log.info("Google sheets ingestion complete")

    s3_path = f"s3://{DEST_BUCKET}/raw/stores/stores.parquet"  
    ti.xcom_push(key="s3_path", value=s3_path)

    send_slack_message("Alert: *Google sheets ingestion complete*")