#Airflow calls these functions automatically when something happens, they are attached to default_args

import logging
from include.slack import send_slack_message

log = logging.getLogger(__name__)

#Airflow calls this function whenever a task fails and task_id is used from context to know which task in particular
def on_failure_alert(context):
    """Airflow provides context variables in dictionary, hence the use of keys"""
    task_id = context["task_instance"].task_id
    run_id  = context["run_id"]
    ds      = context['"ds']
    error   = context.get("exception", "no error message returned")

    #Pulling job_id from XCom incase if any airbyte task fails
    job_id = context["ti"].xcom_pull(task_ids=task_id)

    #Log failure on container
    log.error("Task failed | task=%s | run=%s | date=%s | error=%s", task_id, run_id, ds, error)

    #Send slack message with full context to know which task broke
    