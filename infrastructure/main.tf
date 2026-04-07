# ROOT MODULE
# Orchestrates all three modules and handles the Snowflake trust policy connection 
# which needs outputs from both S3 and Snowflake modules.


# SSM: POSTGRES CREDENTIALS (mentor's admin account)
data "aws_ssm_parameter" "postgres_host" {
  provider        = aws.admin_account
  name            = "/supplychain360/db/host"
  with_decryption = false
}

data "aws_ssm_parameter" "postgres_dbname" {
  provider        = aws.admin_account
  name            = "/supplychain360/db/dbname"
  with_decryption = false
}

data "aws_ssm_parameter" "postgres_port" {
  provider        = aws.admin_account
  name            = "/supplychain360/db/port"
  with_decryption = false
}

data "aws_ssm_parameter" "postgres_username" {
  provider        = aws.admin_account
  name            = "/supplychain360/db/user"
  with_decryption = false
}

data "aws_ssm_parameter" "postgres_password" {
  provider        = aws.admin_account
  name            = "/supplychain360/db/password"
  with_decryption = true
}


# SSM: AIRBYTE S3 ACCESS KEYS

data "aws_ssm_parameter" "source_aws_access_key_id" {
  name            = "/supplychain360/airbyte/source_access_key_id"
  with_decryption = true
}

data "aws_ssm_parameter" "source_aws_secret_access_key" {
  name            = "/supplychain360/airbyte/source_secret_access_key"
  with_decryption = true
}

data "aws_ssm_parameter" "datalake_aws_access_key_id" {
  name            = "/supplychain360/airbyte/datalake_access_key_id"
  with_decryption = true
}

data "aws_ssm_parameter" "datalake_aws_secret_access_key" {
  name            = "/supplychain360/airbyte/datalake_secret_access_key"
  with_decryption = true
}


# SSM: SNOWFLAKE PASSWORD

data "aws_ssm_parameter" "snowflake_password" {
  name            = "/supplychain360/snowflake/password"
  with_decryption = true
}

# SSM: AIRBYTE CLIENT CREDENTIALS
# Used to authenticate with Airbyte Cloud.

data "aws_ssm_parameter" "airbyte_client_id" {
  name            = "/supplychain360/airbyte/client_id"
  with_decryption = true
}

data "aws_ssm_parameter" "airbyte_client_secret" {
  name            = "/supplychain360/airbyte/client_secret"
  with_decryption = true
}


# MODULE: S3
# Creates data lake bucket + Snowflake IAM role with no trust policy for now,
#because snowflake real ARN does not exist yet
#This module gets two outputs for us: S3 role ARN and bucket name destination for Airbyte

module "s3" {
  source = "./modules/s3"

  destination_bucket_name = var.destination_bucket_name
  project_name            = var.project_name
}

# MODULE: SNOWFLAKE
# Creates all Snowflake infrastructure.
# It then assumes s3 IAM role to read from s3 and also create storage integration
#It produces two outputs: snowflake storage user ARN and extrenal ID, to establish trust policy


module "snowflake" {
  source = "./modules/snowflake"

  database_name           = var.snowflake_database
  warehouse_name          = var.snowflake_warehouse
  destination_bucket_name = var.destination_bucket_name
  snowflake_s3_role_arn   = module.s3.snowflake_s3_role_arn
}


# SNOWFLAKE TRUST POLICY 
# This lives in root because it needs outputs from BOTH modules:
#   - IAM role name from module.s3
#   - Snowflake IAM user ARN + external ID from module.snowflake
#
# How it works:
#   1. S3 module creates the IAM role with a Deny placeholder
#   2. Snowflake module creates the storage integration
#   3. Snowflake generates a unique IAM user ARN + external ID
#   4. Root module connects the IAM role trust policy with those real values
#   5. Snowflake can now assume the role and read from S3

data "aws_iam_policy_document" "snowflake_s3_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [module.snowflake.storage_aws_iam_user_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [module.snowflake.storage_aws_external_id]
    }
  }

  depends_on = [module.snowflake]
}

resource "aws_iam_role" "snowflake_s3_trust_patch" {
  name               = "${var.project_name}-snowflake-s3-role"
  assume_role_policy = data.aws_iam_policy_document.snowflake_s3_trust_policy.json

  tags = {
    Name      = "${var.project_name}-snowflake-s3-role"
    Project   = var.project_name
    ManagedBy = "supply-chain-terraform-state-de-kate"
  }

  depends_on = [module.snowflake]
}


# MODULE: AIRBYTE
# Creates sources, destination, and connections.
# Depends on S3 module for destination bucket name.
# All credentials come from SSM nothing hardcoded.

module "airbyte" {
  source = "./modules/airbyte"

  airbyte_workspace_id    = var.airbyte_workspace_id
  source_bucket_name      = var.source_bucket_name
  destination_bucket_name = module.s3.destination_bucket_name
  aws_region              = var.aws_region 

  # S3 access keys from SSM
  source_aws_access_key_id       = data.aws_ssm_parameter.source_aws_access_key_id.value
  source_aws_secret_access_key   = data.aws_ssm_parameter.source_aws_secret_access_key.value
  datalake_aws_access_key_id     = data.aws_ssm_parameter.datalake_aws_access_key_id.value
  datalake_aws_secret_access_key = data.aws_ssm_parameter.datalake_aws_secret_access_key.value

  # Postgres credentials from SSM
  postgres_host     = data.aws_ssm_parameter.postgres_host.value
  postgres_port     = data.aws_ssm_parameter.postgres_port.value
  postgres_database = data.aws_ssm_parameter.postgres_dbname.value
  postgres_username = data.aws_ssm_parameter.postgres_username.value
  postgres_password = data.aws_ssm_parameter.postgres_password.value
}