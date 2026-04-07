from airflow.providers.slack.hooks.slack_webhook import SlackWebhookHook

SLACK_CONNECTION_ID = "slack_webhook"

def send_slack_message(message):
    hook = SlackWebhookHook(slack_webhook_conn_id=SLACK_CONNECTION_ID)
    hook.send(text=message)
    
