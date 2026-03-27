output "destination_bucket_name" {
  description = "Name of the S3 data lake bucket"
  value       = aws_s3_bucket.raw_supplychain_data_DEKate.id
}

output "bucket_arn" {
  description = "ARN of the S3 data lake bucket — needed by Snowflake storage integration"
  value       = aws_s3_bucket.raw_supplychain_data_DEKate.arn
}

output "snowflake_role_arn" {
  description = "ARN of the IAM role Snowflake assumes to read from S3"
  value       = aws_iam_role.snowflake_s3_role.arn
}

output "airbyte_role_arn" {
  description = "ARN of the IAM role Airbyte uses to write to S3"
  value       = aws_iam_role.airbyte_s3_role.arn
}
output "destination_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.raw_supplychain_data_DEKate.arn
}