variable "destination_bucket_name" {
  description = "Name of the S3 data lake bucket"
  type        = string
}

variable "project_name" {
  description = "Project name used for naming and tagging all resources"
  type        = string
}


# These two come from the Snowflake module outputs via root main.tf.
# They use placeholder values on the first apply because the Snowflake
# storage integration does not exist yet on first run.
# On second apply, root main.tf passes the real values in.

variable "snowflake_iam_user_arn" {
  description = "Snowflake AWS IAM user ARN from storage integration output"
  type        = string
  default     = "arn:aws:iam::000000000000:root"
}

variable "snowflake_external_id" {
  description = "Snowflake external ID from storage integration output"
  type        = string
  default     = "placeholder"
}

variable "airbyte_workspace_id" {
  description = "External id for airbyte role"
  type        = string
  default     = ""

}