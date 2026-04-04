from cosmos.config import ProjectConfig, ExecutionConfig, ProfileConfig
from cosmos.profiles import SnowflakeUserPasswordProfileMapping
from airflow import DAG
from cosmos import DbtDag, ProjectConfig, ProfileConfig, RenderConfig
from datetime import datetime

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

kate_dag = DbtDag(
    # dbt/cosmos-specific parameters
    project_config=ProjectConfig(DBT_PROJECT_PATH),
    profile_config=profile_config,
    execution_config=exec_config,
    operator_args={
        "install_deps": True,  # install any necessary dependencies before running any dbt command
        "full_refresh": True,  # used only in dbt commands that support this flag
    },
    # normal dag parameters
    schedule="@daily",
    start_date=datetime(2023, 1, 1),
    catchup=False,
    dag_id="kate_cosmos_dag",
    default_args={"retries": 0},
)
