import logging
import requests
from airflow.models import Variable

log = logging.getLogger(__name__)

AIRBYTE_API_BASE = "https://api.airbyte.com"

def get_headers():
    """
    Fetches a fresh OAuth2 access token using Client ID and Secret.
    Airbyte Cloud tokens expire quickly, so we generate a new one per task.
    """
    client_id = Variable.get("AIRBYTE_CLIENT_ID").strip()
    client_secret = Variable.get("AIRBYTE_CLIENT_SECRET").strip()

    auth_url = f"{AIRBYTE_API_BASE}/v1/applications/token"
    
    payload = {
        "client_id": client_id,
        "client_secret": client_secret
    }

    try:
        response = requests.post(auth_url, json=payload, timeout=10)
        response.raise_for_status()
        token = response.json().get("access_token")
        
        return {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
    except Exception as e:
        log.error(f"Failed to authenticate with Airbyte Cloud: {str(e)}")
        raise

def extract_job_id(response):
    body = response.json()
    job_id = body.get("jobId")

    if not job_id:
        raise ValueError(f"Airbyte did not return JobID. Response: {body}")

    log.info(f"Airbyte sync triggered successfully. Job ID: {job_id}")
    return str(job_id)

def is_sync_complete(response):
    body = response.json()
    status = body.get("status", "unknown").lower()

    log.info(f"Polling Airbyte Job | status={status}")

    if status == "succeeded":
        return True

    if status in ("failed", "cancelled"):
        raise Exception(f"Airbyte job failed with status: {status}. Check Cloud UI.")

    return False

def verify_job(source_name, **context):
    ti = context["ti"]
    ds = context["ds"]

    trigger_task_id = f"trigger_{source_name}_sync"
    job_id = ti.xcom_pull(task_ids=trigger_task_id)

    if not job_id:
        raise ValueError(f"No job_id found in XCom for {trigger_task_id}")

    response = requests.get(
        f"{AIRBYTE_API_BASE}/v1/jobs/{job_id}",
        headers=get_headers(),
        timeout=30,
    )

    if response.status_code != 200:
        raise Exception(f"Verification failed: {response.status_code} - {response.text}")

    body = response.json()
    status = body.get("status", "unknown").lower()

    if status == "succeeded":
        log.info(f"Job {job_id} verified successfully.")
        ti.xcom_push(
            key=f"job_summary_{source_name}",
            value={
                "source": source_name,
                "job_id": job_id,
                "status": status,
                "date": ds
            }
        )
    else:
        raise Exception(f"Airbyte job {job_id} failed verification. Status: {status}")
