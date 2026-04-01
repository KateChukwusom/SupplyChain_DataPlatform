# ─────────────────────────────────────────────────────────────
# GENERAL
# ─────────────────────────────────────────────────────────────
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "admin_region" {
  description = "AWS region where mentor SSM parameters are stored"
  type        = string
}

variable "project_name" {
  description = "Project name used for naming and tagging all resources"
  type        = string
  default     = "supplychain-dataplatform"
}

# ─────────────────────────────────────────────────────────────
# S3
# ─────────────────────────────────────────────────────────────
variable "source_bucket_name" {
  description = "Name of the existing source S3 bucket where raw files live"
  type        = string
}

variable "destination_bucket_name" {
  description = "Name of the new data lake S3 bucket Terraform creates"
  type        = string
}

# ─────────────────────────────────────────────────────────────
# SNOWFLAKE
# ─────────────────────────────────────────────────────────────
variable "snowflake_organization" {
  description = "Snowflake organization name"
  type        = string
}

variable "snowflake_account" {
  description = "Snowflake account name"
  type        = string
}

variable "snowflake_user" {
  description = "Snowflake user Terraform authenticates as"
  type        = string
}

variable "snowflake_role" {
  description = "Snowflake role Terraform authenticates with"
  type        = string
}

variable "snowflake_warehouse" {
  description = "Name of the Snowflake warehouse to create"
  type        = string
}

variable "snowflake_database" {
  description = "Name of the Snowflake database to create"
  type        = string
}

# ─────────────────────────────────────────────────────────────
# AIRBYTE
# ─────────────────────────────────────────────────────────────
variable "airbyte_workspace_id" {
  description = "Airbyte Cloud workspace ID"
  type        = string
}