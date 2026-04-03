FROM apache/airflow:3.1.5-python3.11

USER root

# System dependencies needed to compile Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create isolated dbt virtual environment — fixes the protobuf/cryptography
# dependency war by keeping dbt completely separate from Airflow's globals.
# - dbt pinned to 1.8 (most stable with Cosmos + Snowflake)
# - protobuf pinned to satisfy dbt-snowflake without breaking Airflow
# - --no-deps + --ignore-installed acts as a firewall against venv leaking
RUN python3 -m venv /usr/local/airflow/dbt-venv && \
    /usr/local/airflow/dbt-venv/bin/pip install --no-cache-dir \
        "dbt-core==1.8.*" \
        "dbt-snowflake==1.8.*" \
        "protobuf>=4.0,<5.0" && \
    chown -R airflow:root /usr/local/airflow/dbt-venv && \
    chmod -R 775 /usr/local/airflow/dbt-venv

USER airflow

# Upgrade pip cleanly
RUN pip install --upgrade pip --no-cache-dir

# Install Airflow providers and Cosmos — constrained to prevent dependency conflicts
COPY --chown=airflow:root requirements.txt /opt/airflow/requirements.txt

RUN pip install --no-cache-dir \
    --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-3.1.5/constraints-3.11.txt" \
    -r /opt/airflow/requirements.txt