output "database_name" {
  description = "Snowflake database name"
  value       = snowflake_database.supplychain_DATABASE.name
}

output "warehouse_name" {
  description = "Snowflake virtual warehouse name"
  value       = snowflake_warehouse.supplychain.name
}

output "raw_schema" {
  description = "RAW schema name"
  value       = snowflake_schema.raw_SUPPLYCHAIN.name
}

output "staging_schema" {
  description = "STAGING schema name"
  value       = snowflake_schema.staging_SUPPLYCHAIN.name
}

output "marts_schema" {
  description = "MARTS schema name"
  value       = snowflake_schema.marts_SUPPLYCHAIN.name
}

output "stage_name" {
  description = "External S3 stage name - used in COPY INTO commands"
  value       = snowflake_stage.s3_raw.name
}

# These two are the most critical outputs in the entire project.
# Root main.tf passes these back into the S3 module so it can update
# the Snowflake IAM role trust policy with real values on second apply.
output "storage_aws_iam_user_arn" {
  description = "Snowflake AWS IAM user ARN - goes into S3 IAM role trust policy"
  value       = snowflake_storage_integration.s3.storage_aws_iam_user_arn
}

output "storage_aws_external_id" {
  description = "Snowflake external ID - goes into S3 IAM role trust policy condition"
  value       = snowflake_storage_integration.s3.storage_aws_external_id
}