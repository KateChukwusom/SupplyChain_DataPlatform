
variable "warehouse_name" {
  description = "Name of the Snowflake warehouse"
  type        = string
}

variable "database_name" {
  description = "Name of the Snowflake database"
  type        = string
}

variable "snowflake_s3_role_arn" {
  description = "ARN of the AWS IAM role Snowflake assumes to access S3"
  type        = string
}

variable "destination_bucket_name" {
  description = "Name of the S3 data lake bucket"
  type        = string
}