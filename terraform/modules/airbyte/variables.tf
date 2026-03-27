variable "airbyte_workspace_id" {
  description = "Airbyte Cloud workspace ID"
  type        = string
}

variable "source_bucket_name" {
  description = "S3 data lake bucket name"
  type        = string
}

variable "destination_bucket_name" {
  description = "Name of the s3 data lake that airbyte writes to"
  type = string
  
}
variable "aws_region" {
  description = "AWS region where the S3 bucket lives"
  type        = string
}

variable "airbyte_role_arn" {
  description = "IAM role ARN Airbyte Cloud assumes to write to S3"
  type        = string
}

variable "postgres_host" {
  description = "Hostname of Postgres database"
  type        = string
}

variable "postgres_port" {
  description = "Port of Postgres database"
  type        = string
  default     = "6543"
}

variable "postgres_database" {
  description = "Name of Postgres database"
  type        = string
}

variable "postgres_username" {
  description = "Username of Postgres database"
  type        = string
}

variable "postgres_password" {
  description = "Password for the source Postgres database"
  type        = string
  sensitive   = true
}

