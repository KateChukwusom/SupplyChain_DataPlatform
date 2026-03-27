
# Declares every input variable the root module accepts.
# Actual values live in terraform.tfvars 

variable "aws_region" {
  description = "AWS region where all resources are deployed"
  type        = string
}

variable "project_name" {
  description = "Project name used for naming and tagging all resources"
  type        = string
  default     = "supplychain-dataplatform"
}

variable "source_bucket_name" {
  description = "Name of the already existing data lake"
  type        = string
}

variable "destination_bucket_name" {
  description = "Name of the new data lake that terraform creates"
  type        = string

}

variable "snowflake_organization" {
  description = "Snowflake organization name — found in Snowflake UI bottom left"
  type        = string
}

variable "snowflake_account" {
  description = "Snowflake account name — the part after the org name"
  type        = string
}

variable "snowflake_user" {
  description = "Snowflake user"
  type        = string
}

variable "snowflake_password" {
  description = "Snowflake password"
  type        = string
  sensitive   = true
}

variable "snowflake_role" {
  description = "Snowflake role Terraform authenticates with"
  type        = string
  default     = "ACCOUNTADMIN"
}

variable "snowflake_warehouse" {
  description = "Name of the Snowflake virtual warehouse to create"
  type        = string
}

variable "snowflake_database" {
  description = "Name of the Snowflake database to create"
  type        = string
}

variable "airbyte_workspace_id" {
  description = "Airbyte Cloud workspace ID"
  type        = string
}

variable "airbyte_client_id" {
  description = "Airbyte Cloud client ID "
  type        = string
  sensitive   = true
}

variable "airbyte_client_secret" {
  description = "Airbyte Cloud client secret "
  type        = string
  sensitive   = true
}

variable "admin_region" {
  description = "AWS region where mentor's SSM parameters are stored"
  type        = string
}