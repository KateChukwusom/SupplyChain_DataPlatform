FROM apache/airflow:3.1.5-python3.11

USER root
RUN apt-get update && apt-get install -y \
    gcc \
    && apt-get clean

USER airflow

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
```

 `requirements.txt`
```
apache-airflow-providers-amazon
apache-airflow-providers-snowflake
apache-airflow-providers-postgres
apache-airflow-providers-google
apache-airflow-providers-celery
apache-airflow-providers-fab