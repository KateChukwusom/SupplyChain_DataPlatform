import logging
from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook
from airflow.models import Variable
from include.slack import send_slack_message

log = logging.getLogger(__name__)

SNOWFLAKE_CONN_ID = "snowflake_connection"

#stage name
SNOWFLAKE_STAGE = Variable.get("SNOWFLAKE_STAGE")

# Airbyte S3 source streams
AIRBYTE_S3_STREAMS = ["inventory", "suppliers", "products", "warehouses"]

# Airbyte Postgres streams — all date partitions live under a single sales/ folder
AIRBYTE_POSTGRES_STAGE_PATH = "sales/"
AIRBYTE_POSTGRES_TABLE = "sales"

#create a table by inferring schema from each parquet files
def _infer_and_create_table(hook: SnowflakeHook, table: str, stage_path: str):

    create_sql = f"""
        CREATE TABLE IF NOT EXISTS RAW_SUPPLYCHAIN.{table}
        USING TEMPLATE (
            SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
            FROM TABLE(
                INFER_SCHEMA(
                    LOCATION => '@{SNOWFLAKE_STAGE}/{stage_path}',
                    FILE_FORMAT => 'PARQUET_FORMAT'
                )
            )
        )
    """
    log.info("Creating table if not exists | table=%s | stage_path=%s", table, stage_path)
    hook.run(create_sql)

#Run COPY INTO for every table and path
def _run_copy_into(hook: SnowflakeHook, table: str, stage_path: str, source_name: str) -> dict:
    
    copy_sql = f"""
        COPY INTO RAW_SUPPLYCHAIN.{table}
        FROM @{SNOWFLAKE_STAGE}/{stage_path}
        FILE_FORMAT = (TYPE = 'PARQUET')
        MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
        PURGE = FALSE
        ON_ERROR = ABORT_STATEMENT
    """

    log.info(
        "Running COPY INTO | source=%s | table=%s | stage_path=%s",
        source_name, table, stage_path,
    )

    results = hook.run(copy_sql, handler=lambda cursor: cursor.fetchall())
    total_rows_loaded = sum(row[3] for row in results) if results else 0

    if total_rows_loaded == 0:
        log.warning(
            "COPY INTO loaded 0 rows | source=%s | table=%s | ",
            source_name, table,
        )
    else:
        log.info(
            "COPY INTO complete | source=%s | table=%s | rows_loaded=%s",
            source_name, table, total_rows_loaded,
        )

    return {
        "source": source_name,
        "table": table,
        "stage_path": stage_path,
        "rows_loaded": total_rows_loaded,
        "status": "success",
    }

#Load shipments parquet files into snowflake by calling the function _run_copy_into
def copy_shipments_into_snowflake(**context):
    """
    Loads shipments Parquet files into Snowflake.
    Path comes from XCom pushed by ingest_s3_file.
    Shipments uses its own watermark-based partitioning:
    e.g. raw/shipments/shipments_2026-03-12.parquet
    """
    ti = context["ti"]
    ds = context["ds"]

    s3_path = ti.xcom_pull(task_ids="ingest_s3_file", key="s3_path")

    if not s3_path:
        raise ValueError(
            "No S3 path found in XCom from task 'ingest_s3_file'. "
            "That task may have failed without raising properly."
        )

    # Stage already points to raw/ so we only need what comes after
    stage_path = s3_path.split("/raw/", 1)[-1] if "/raw/" in s3_path else s3_path

    hook = SnowflakeHook(snowflake_conn_id=SNOWFLAKE_CONN_ID)
    _infer_and_create_table(hook, "shipments", stage_path)
    summary = _run_copy_into(hook, "shipments", stage_path, "shipments")

    ti.xcom_push(key="load_summary_shipments", value=summary)

    send_slack_message(
        
        f">*Date:* `{ds}`\n"
        f">*Rows loaded:* `{summary['rows_loaded']}`"
    )


def copy_stores_into_snowflake(**context):
    """
    Loads Google Sheets stores data into Snowflake.
    Path comes from XCom pushed by ingest_google_sheets.
    """
    ti = context["ti"]
    ds = context["ds"]

    s3_path = ti.xcom_pull(task_ids="ingest_google_sheets", key="s3_path")

    if not s3_path:
        raise ValueError(
            "No S3 path found in XCom from task 'ingest_google_sheets'. "
            "That task may have failed without raising properly."
        )

    stage_path = s3_path.split("/raw/", 1)[-1] if "/raw/" in s3_path else s3_path

    hook = SnowflakeHook(snowflake_conn_id=SNOWFLAKE_CONN_ID)
    _infer_and_create_table(hook, "stores", stage_path)
    summary = _run_copy_into(hook, "stores", stage_path, "stores")

    ti.xcom_push(key="load_summary_stores", value=summary)

    send_slack_message(
        
        f">*Date:* `{ds}`\n"
        f">*Rows loaded:* `{summary['rows_loaded']}`"
    )


def copy_airbyte_s3_into_snowflake(**context):
    """
    Loads all Airbyte S3 streams into Snowflake.
    Airbyte writes to raw/{stream_name}/ in the destination bucket.
    Loops over all streams and loads each into its own table.
    """
    ds = context["ds"]
    hook = SnowflakeHook(snowflake_conn_id=SNOWFLAKE_CONN_ID)
    summaries = []

    for stream in AIRBYTE_S3_STREAMS:
        stage_path = f"{stream}/"
        _infer_and_create_table(hook, stream, stage_path)
        summary = _run_copy_into(hook, stream, stage_path, source_name=f"airbyte_s3_{stream}")
        summaries.append(summary)

    context["ti"].xcom_push(key="load_summary_airbyte_s3", value=summaries)

    total_rows = sum(s["rows_loaded"] for s in summaries)
    send_slack_message(
        
        f">*Date:* `{ds}`\n"
        f">*Streams:* `{', '.join(AIRBYTE_S3_STREAMS)}`\n"
        f">*Total rows loaded:* `{total_rows}`"
    )


AIRBYTE_POSTGRES_STREAMS = [
    "sales_2026_03_10",
    "sales_2026_03_11",
    "sales_2026_03_12",
    "sales_2026_03_13",
    "sales_2026_03_14",
    "sales_2026_03_15",
    "sales_2026_03_16",
]

def copy_airbyte_postgres_into_snowflake(**context):
    ds = context["ds"]
    hook = SnowflakeHook(snowflake_conn_id=SNOWFLAKE_CONN_ID)
    summaries = []

    # Create the single sales table once using the first stream's schema
    _infer_and_create_table(hook, "sales", f"{AIRBYTE_POSTGRES_STREAMS[0]}/")

    # Load each date partition into the same sales table
    for stream in AIRBYTE_POSTGRES_STREAMS:
        stage_path = f"{stream}/"
        summary = _run_copy_into(hook, "sales", stage_path, source_name=f"airbyte_postgres_{stream}")
        summaries.append(summary)

    context["ti"].xcom_push(key="load_summary_airbyte_postgres", value=summaries)

    total_rows = sum(s["rows_loaded"] for s in summaries)
    send_slack_message(
        f":large_blue_circle: *Airbyte Postgres sales loaded into Snowflake*\n"
        f">*Date:* `{ds}`\n"
        f">*Streams:* `{', '.join(AIRBYTE_POSTGRES_STREAMS)}`\n"
        f">*Total rows loaded:* `{total_rows}`"
    )