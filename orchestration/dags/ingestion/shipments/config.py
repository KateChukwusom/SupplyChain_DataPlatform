import boto3
from airflow.providers.amazon.aws.hooks.base_aws import AwsBaseHook


SOURCE_BUCKET     = "supplychain360-data"
SOURCE_PREFIX     = "raw/shipments/"
DEST_BUCKET       = "raw-supplychain360-dekatede"
DEST_PREFIX       = "raw/shipments/"


CHECKPOINT_BUCKET = "raw-supplychain360-dekatede"
CHECKPOINT_KEY    = "checkpoints/shipments_checkpoint.json"


MAX_RETRIES   = 3
RETRY_BACKOFF = 2


SSM_SOURCE_ACCESS_KEY_ID     = "/supplychain360/airbyte/source_access_key_id"
SSM_SOURCE_SECRET_ACCESS_KEY = "/supplychain360/airbyte/source_secret_access_key"
SSM_DATALAKE_ACCESS_KEY_ID     = "/supplychain360/airbyte/datalake_access_key_id"
SSM_DATALAKE_SECRET_ACCESS_KEY = "/supplychain360/airbyte/datalake_secret_access_key"


def get_s3_clients():
    hook = AwsBaseHook(aws_conn_id="aws_ssm", client_type="ssm", region_name="eu-west-1")
    ssm = hook.get_client_type()

    def get(name):
        return ssm.get_parameter(Name=name, WithDecryption=True)["Parameter"]["Value"]

    source_s3 = boto3.client(
        "s3",
        aws_access_key_id     = get(SSM_SOURCE_ACCESS_KEY_ID),
        aws_secret_access_key = get(SSM_SOURCE_SECRET_ACCESS_KEY),
        region_name           = "eu-west-2"
    )

    dest_s3 = boto3.client(
        "s3",
        aws_access_key_id     = get(SSM_DATALAKE_ACCESS_KEY_ID),
        aws_secret_access_key = get(SSM_DATALAKE_SECRET_ACCESS_KEY),
        region_name           = "eu-west-1"
    )

    return source_s3, dest_s3