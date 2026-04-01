terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.87"
    }
    airbyte = {
      source  = "airbytehq/airbyte"
      version = "~> 0.6"
    }
  }
}

# ─────────────────────────────────────────────────────────────
# AWS — DEFAULT (your own account)
# Used for S3 bucket, Airbyte SSM parameters,
# Snowflake SSM parameters, and trust policy patch.
# ─────────────────────────────────────────────────────────────
provider "aws" {
  region = "eu-west-1"  
}

# ─────────────────────────────────────────────────────────────
# AWS — ADMIN ACCOUNT (mentor's account)
# Used only for reading Postgres SSM parameters.
# Requires "admin" profile configured in ~/.aws/credentials
# ─────────────────────────────────────────────────────────────
provider "aws" {
  alias   = "admin_account"
  region  = var.admin_region
  profile = "admin"
}

# ─────────────────────────────────────────────────────────────
# SNOWFLAKE
# Authenticates as your Terraform user with ACCOUNTADMIN role.
# Password pulled from SSM — never hardcoded.
# preview_features_enabled kept for safety — harmless if not needed.
# ─────────────────────────────────────────────────────────────
provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account
  user              = var.snowflake_user
  password          = data.aws_ssm_parameter.snowflake_password.value # uncommented
  role              = var.snowflake_role


}

# ─────────────────────────────────────────────────────────────
# AIRBYTE
# Authenticates with Airbyte Cloud using client credentials.
# Both values pulled from SSM — never hardcoded.
# ─────────────────────────────────────────────────────────────
provider "airbyte" {
  client_id     = data.aws_ssm_parameter.airbyte_client_id.value
  client_secret = data.aws_ssm_parameter.airbyte_client_secret.value
}