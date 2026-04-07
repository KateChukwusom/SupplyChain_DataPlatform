
# S3 OUTPUTS

output "destination_bucket_name" {
  description = "Name of the data lake S3 bucket"
  value       = module.s3.destination_bucket_name
}

output "snowflake_s3_role_arn" {
  description = "ARN of the IAM role Snowflake assumes to read from S3"
  value       = module.s3.snowflake_s3_role_arn
}


# SNOWFLAKE OUTPUTS

output "snowflake_iam_user_arn" {
  description = "Snowflake IAM user ARN — used in IAM trust policy"
  value       = module.snowflake.storage_aws_iam_user_arn
}

output "snowflake_external_id" {
  description = "Snowflake external ID — used in IAM trust policy condition"
  value       = module.snowflake.storage_aws_external_id
}


# AIRBYTE OUTPUTS

output "airbyte_s3_connection_id" {
  description = "Airbyte connection ID for S3 source — used by Airflow to trigger syncs"
  value       = module.airbyte.s3_connection_id
}

output "airbyte_postgres_connection_id" {
  description = "Airbyte connection ID for Postgres source — used by Airflow to trigger syncs"
  value       = module.airbyte.postgres_connection_id
}