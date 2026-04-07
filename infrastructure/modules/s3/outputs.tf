# # These two outputs are consumed by the root module.
# # destination_bucket_name → passed into Airbyte module
# # snowflake_s3_role_arn   → passed into Snowflake module + trust policy patch


output "destination_bucket_name" {
  description = "Name of the created data lake S3 bucket"
  value       = aws_s3_bucket.data_lake.bucket
}

output "snowflake_s3_role_arn" {
  description = "ARN of Snowflake IAM role — used by root trust policy patch"
  value       = aws_iam_role.snowflake_s3_role.arn
}