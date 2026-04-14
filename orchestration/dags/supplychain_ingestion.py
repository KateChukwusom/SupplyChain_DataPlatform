import json
from datetime import datetime, timedelta
import requests
from airflow.sdk import Variable, DAG
from airflow.providers.standard.operators.python import PythonOperator
from airflow.providers.http.operators.http import HttpOperator
from airflow.providers.http.sensors.http import HttpSensor
from airflow.providers.standard.operators.trigger_dagrun import TriggerDagRunOperator


# Imports
from include.slack import send_slack_message
from include.callbacks import on_failure_alert
from include.ingestion import ingest_s3_file, ingest_google_sheets
from include.airbyte import verify_job
from include.snowflake import (
    copy_shipments_into_snowflake,
    copy_stores_into_snowflake,
    copy_airbyte_s3_into_snowflake,
    copy_airbyte_postgres_into_snowflake,
)

AIRBYTE_CONN_ID = "airbyte_connection"
AIRBYTE_API_BASE = "https://api.airbyte.com"


AIRBYTE_S3_CONNECTION_ID = Variable.get("airbyte_s3_s3_connection_id")
AIRBYTE_POSTGRES_CONNECTION_ID = Variable.get("airbyte_postgres_s3_connection_id")


def get_headers():
    # Use Client ID/Secret instead of a static token to prevent "Unauthorized"
    client_id = Variable.get("AIRBYTE_CLIENT_ID").strip()
    client_secret = Variable.get("AIRBYTE_CLIENT_SECRET").strip()

    auth_url = f"{AIRBYTE_API_BASE}/v1/applications/token"
    
    # Generate fresh token
    auth_resp = requests.post(
        auth_url, 
        json={"client_id": client_id, "client_secret": client_secret},
        timeout=10
    )
    auth_resp.raise_for_status()
    token = auth_resp.json().get("access_token")

    if not token:
        raise ValueError("AIRBYTE_API_TOKEN could not be generated")

    return {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }


# Response
def extract_job_id(response):
    body = response.json()
    job_id = body.get("jobId") 

    if not job_id:
        raise ValueError(f"No jobId returned. Response: {body}")

    return str(job_id)


def is_sync_complete(response):
    body = response.json()
    status = body.get("status", "unknown").lower()

    if status == "succeeded":
        return True

    if status in ("failed", "cancelled"):
        raise Exception(f"Airbyte job failed: {body}")

    return False


# Downstream tasks
def run_downstream(**context):
    ti = context["ti"]
    ds = context["ds"]

    s3_summary = ti.xcom_pull(task_ids="copy_s3_file_into_snowflake", key="load_summary_shipments")
    sheets_summary = ti.xcom_pull(task_ids="copy_google_sheets_into_snowflake", key="load_summary_stores")
    airbyte_s3_summary = ti.xcom_pull(task_ids="copy_airbyte_s3_into_snowflake", key="load_summary_airbyte_s3")
    airbyte_postgres_summary = ti.xcom_pull(task_ids="copy_airbyte_postgres_into_snowflake", key="load_summary_airbyte_postgres")

    total_airbyte_s3_rows = sum(s["rows_loaded"] for s in airbyte_s3_summary)
    total_airbyte_postgres_rows = sum(s["rows_loaded"] for s in airbyte_postgres_summary)

    send_slack_message(
        f": All sources loaded\n\n"
        f" `{ds}`\n\n"
        f"S3 source\n"
        f"Table: `{s3_summary['table']}`\n"
        f"Rows loaded: `{s3_summary['rows_loaded']}`\n\n"
        f"Google Sheets\n"
        f"Table: `{sheets_summary['table']}`\n"
        f"Rows loaded: `{sheets_summary['rows_loaded']}`\n\n"
        f"Airbyte S3 streams\n"
        f"Total rows loaded: `{total_airbyte_s3_rows}`\n\n"
        f"Airbyte Postgres sales\n"
        f"Total rows loaded: `{total_airbyte_postgres_rows}`"
    )


# DAG
default_args = {
    "owner": "data-team",
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "on_failure_callback": on_failure_alert,
}

with DAG(
    dag_id="full_ingestion_pipeline",
    default_args=default_args,
    start_date=datetime(2025, 1, 1),
    schedule=None,
    catchup=False,
    max_active_runs=1,
    tags=["ingestion", "airbyte", "snowflake"],
) as dag:

    #  S3
    ingest_s3 = PythonOperator(
        task_id="ingest_s3_file",
        python_callable=ingest_s3_file,
    )

    load_s3 = PythonOperator(
        task_id="copy_s3_file_into_snowflake",
        python_callable=copy_shipments_into_snowflake,
    )

    # GOOGLE SHEETS 
    ingest_sheets = PythonOperator(
        task_id="ingest_google_sheets",
        python_callable=ingest_google_sheets,
    )

    load_sheets = PythonOperator(
        task_id="copy_google_sheets_into_snowflake",
        python_callable=copy_stores_into_snowflake,
    )

    # AIRBYTE S3 
    trigger_airbyte_s3 = HttpOperator(
        task_id="trigger_airbyte_s3_sync",
        http_conn_id=AIRBYTE_CONN_ID,
        endpoint="/v1/jobs",
        method="POST",
        headers=get_headers(),
        data=json.dumps({
            "connectionId": AIRBYTE_S3_CONNECTION_ID,
            "jobType": "sync",
        }),
        response_filter=extract_job_id,
        response_check=lambda r: r.status_code in (200, 201),
        log_response=True,
    )

    poll_airbyte_s3 = HttpSensor(
        task_id="poll_airbyte_s3_sync",
        http_conn_id=AIRBYTE_CONN_ID,
        endpoint="/v1/jobs/{{ ti.xcom_pull(task_ids='trigger_airbyte_s3_sync') }}",
        headers=get_headers(),
        method="GET",
        response_check=is_sync_complete,
        poke_interval=30,
        timeout=3600,
        mode="reschedule",
    )

    verify_s3 = PythonOperator(
        task_id="verify_airbyte_s3_sync",
        python_callable=verify_job,
        op_kwargs={"source_name": "airbyte_s3"},
    )

    load_airbyte_s3 = PythonOperator(
        task_id="copy_airbyte_s3_into_snowflake",
        python_callable=copy_airbyte_s3_into_snowflake,
    )

    #  AIRBYTE POSTGRES 
    trigger_airbyte_pg = HttpOperator(
        task_id="trigger_airbyte_postgres_sync",
        http_conn_id=AIRBYTE_CONN_ID,
        endpoint="/v1/jobs",
        method="POST",
        headers=get_headers(),
        data=json.dumps({
            "connectionId": AIRBYTE_POSTGRES_CONNECTION_ID,
            "jobType": "sync",
        }),
        response_filter=extract_job_id,
        response_check=lambda r: r.status_code in (200, 201),
        log_response=True,
    )

    poll_airbyte_pg = HttpSensor(
        task_id="poll_airbyte_postgres_sync",
        http_conn_id=AIRBYTE_CONN_ID,
        endpoint="/v1/jobs/{{ ti.xcom_pull(task_ids='trigger_airbyte_postgres_sync') }}",
        headers=get_headers(),
        method="GET",
        response_check=is_sync_complete,
        poke_interval=30,
        timeout=3600,
        mode="reschedule",
    )

    verify_pg = PythonOperator(
        task_id="verify_airbyte_postgres_sync",
        python_callable=verify_job,
        op_kwargs={"source_name": "airbyte_postgres"},
    )

    load_airbyte_pg = PythonOperator(
        task_id="copy_airbyte_postgres_into_snowflake",
        python_callable=copy_airbyte_postgres_into_snowflake,
    )

    #  FINAL
    final = PythonOperator(
        task_id="run_downstream",
        python_callable=run_downstream,
    )

    trigger_dbt = TriggerDagRunOperator(
    task_id="trigger_dbt_transformation",
    trigger_dag_id="supplychain_cosmos_dag",
    wait_for_completion=True,
)

# update dependencies
ingest_s3 >> load_s3 >> final
ingest_sheets >> load_sheets >> final
trigger_airbyte_s3 >> poll_airbyte_s3 >> verify_s3 >> load_airbyte_s3 >> final
trigger_airbyte_pg >> poll_airbyte_pg >> verify_pg >> load_airbyte_pg >> final

final >> trigger_dbt