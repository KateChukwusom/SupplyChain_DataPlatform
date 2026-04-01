FROM apache/airflow:3.1.5-python3.11

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# create isolated venv for dbt
RUN python3 -m venv /usr/local/airflow/dbt-venv && \
    /usr/local/airflow/dbt-venv/bin/pip install \
    dbt-core \
    dbt-snowflake

USER airflow
RUN pip install --upgrade pip

COPY --chown=airflow:root requirements.txt /opt/airflow/requirements.txt

RUN pip install --no-cache-dir \
    --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-3.1.5/constraints-3.11.txt" \
    -r /opt/airflow/requirements.txt