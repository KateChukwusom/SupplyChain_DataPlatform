variable "database_name" {
  description = "Name of the Snowflake database to create"
  type        = string
}

variable "warehouse_name" {
  description = "Name of the Snowflake warehouse to create"
  type        = string
}

variable "destination_bucket_name" {
  description = "Data lake S3 bucket name — used in storage integration and stage URL"
  type        = string
}

variable "snowflake_s3_role_arn" {
  description = "ARN of the Snowflake IAM role created in the S3 module"
  type        = string
}