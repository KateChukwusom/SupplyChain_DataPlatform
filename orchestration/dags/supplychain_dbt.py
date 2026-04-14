from cosmos.config import ProjectConfig, ExecutionConfig, ProfileConfig, RenderConfig
from cosmos.profiles import SnowflakeUserPasswordProfileMapping
from airflow import DAG
from cosmos import DbtDag
from datetime import datetime
from cosmos.constants import InvocationMode, LoadMode
from airflow.sdk import Variable


DBT_PROJECT_PATH = "/opt/airflow/dags/dbt/supplychain360"
EXECUTION_PATH = "/usr/local/airflow/dbt-venv/bin/dbt"
PROFILE_NAME = "supplychain360"

project_config = ProjectConfig(
    dbt_project_path= DBT_PROJECT_PATH,
)

exec_config = ExecutionConfig(
    dbt_executable_path= EXECUTION_PATH
)

profile_config = ProfileConfig(
    profile_name=PROFILE_NAME,
    target_name="dev",
    profile_mapping=SnowflakeUserPasswordProfileMapping(
        conn_id="snowflake_connection",
        profile_args={
            "database": "SUPPLYCHAIN_DB",
            "schema": "RAW_SUPPLYCHAIN",
        },
    ),
)


render_config = RenderConfig(
    # Use the cached LS mode to keep the scheduler fast
    load_method=LoadMode.DBT_LS,
    # Explicitly stay in subprocess mode for the venv
    invocation_mode=InvocationMode.SUBPROCESS,
    # Pointer to the specific venv location from the Dockerfile
    dbt_executable_path="/usr/local/airflow/dbt-venv/bin/dbt",
    dbt_deps=False
)
cosmos_dag = DbtDag(
    # dbt/cosmos-specific parameters
    project_config=project_config,
    profile_config=profile_config,
    execution_config=exec_config,
    render_config=render_config,
    operator_args={
        "install_deps": False,
          "append_env": True,  
        "full_refresh": True,
        "env": {
            "COSMOS_CONN_SNOWFLAKE_PASSWORD": Variable.get("COSMOS_CONN_SNOWFLAKE_PASSWORD")
        }
    },
    # normal dag parameters
    schedule=None,
    start_date=datetime(2023, 1, 1),
    catchup=False,
    dag_id="supplychain_cosmos_dag",
    default_args={"retries": 0},
)
