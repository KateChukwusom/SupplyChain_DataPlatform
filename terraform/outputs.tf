# S3

output "destination_bucket_name" {
  description = "Name of the S3 destination data lake bucket"
  value       = module.s3.destination_bucket_name
}

output "destination_bucket_arn" {
  description = "ARN of the S3 destination data lake bucket"
  value       = module.s3.destination_bucket_arn
}

output "snowflake_role_arn" {
  description = "ARN of the IAM role Snowflake assumes to read from S3"
  value       = module.s3.snowflake_role_arn
}

output "airbyte_role_arn" {
  description = "ARN of the IAM role Airbyte assumes to write to S3"
  value       = module.s3.airbyte_role_arn
}


output "snowflake_database" {
  description = "Snowflake database name"
  value       = module.snowflake.database_name
}

output "snowflake_warehouse" {
  description = "Snowflake virtual warehouse name"
  value       = module.snowflake.warehouse_name
}

output "snowflake_raw_schema" {
  description = "Snowflake RAW schema name"
  value       = module.snowflake.raw_schema
}

output "snowflake_stage_name" {
  description = "Snowflake external S3 stage name"
  value       = module.snowflake.stage_name
}

output "airbyte_s3_source_id" {
  description = "Airbyte S3 source ID"
  value       = module.airbyte.s3_source_id
}

output "airbyte_postgres_source_id" {
  description = "Airbyte Postgres source ID"
  value       = module.airbyte.postgres_source_id
}

output "airbyte_s3_connection_id" {
  description = "Airbyte connection ID for S3 source — used by Airflow to trigger syncs"
  value       = module.airbyte.s3_connection_id
}

output "airbyte_postgres_connection_id" {
  description = "Airbyte connection ID for Postgres source — used by Airflow to trigger syncs"
  value       = module.airbyte.postgres_connection_id
}

output "snowflake_iam_user_arn" {
  value = module.snowflake.storage_aws_iam_user_arn
}

output "snowflake_external_id" {
  value = module.snowflake.storage_aws_external_id
}