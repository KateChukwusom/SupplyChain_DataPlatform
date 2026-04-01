# SNOWFLAKE MODULE
# Creates all core Snowflake infrastructure:
#   - Database
#   - Schemas (RAW_SUPPLYCHAIN, STAGING_SUPPLYCHAIN,
#              INTERMEDIATE_SUPPLYCHAIN, MARTS_SUPPLYCHAIN)
#   - Warehouse
#   - Storage Integration (secure S3 access via IAM role)
#   - External Stage (used in COPY INTO)
#
# After creating the storage integration, Snowflake generates
# a unique IAM user ARN and external ID — these are exposed
# as outputs so the root module can patch the IAM role trust policy.

terraform {
  required_providers {
    snowflake = {
      source = "Snowflake-Labs/snowflake"  # fixed
    }
  }
}

# ─────────────────────────────────────────────────────────────
# DATABASE
# ─────────────────────────────────────────────────────────────
resource "snowflake_database" "supplychain_DATABASE" {
  name = var.database_name
}

# ─────────────────────────────────────────────────────────────
# SCHEMAS
# ─────────────────────────────────────────────────────────────

# Airbyte lands raw parquet files here via COPY INTO
resource "snowflake_schema" "raw_SUPPLYCHAIN" {
  database = snowflake_database.supplychain_DATABASE.name
  name     = "RAW_SUPPLYCHAIN"
}

# dbt staging models live here
resource "snowflake_schema" "staging_SUPPLYCHAIN" {
  database = snowflake_database.supplychain_DATABASE.name
  name     = "STAGING_SUPPLYCHAIN"
}

# dbt intermediate models live here
resource "snowflake_schema" "intermediate_SUPPLYCHAIN" {
  database = snowflake_database.supplychain_DATABASE.name
  name     = "INTERMEDIATE_SUPPLYCHAIN"
}

# dbt final models live here
resource "snowflake_schema" "marts_SUPPLYCHAIN" {
  database = snowflake_database.supplychain_DATABASE.name
  name     = "MARTS_SUPPLYCHAIN"
}

# ─────────────────────────────────────────────────────────────
# WAREHOUSE
# Single warehouse for the entire pipeline.
# Auto-suspends after 60s of inactivity to save cost.
# initially_suspended = true means it only starts when needed.
# ─────────────────────────────────────────────────────────────
resource "snowflake_warehouse" "supplychain" {
  name                = var.warehouse_name
  warehouse_size      = "XSMALL"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true  # added — prevents unnecessary cost on creation
}

# ─────────────────────────────────────────────────────────────
# STORAGE INTEGRATION
# Secure trust between Snowflake and your S3 data lake.
# Receives the IAM role ARN from the S3 module.
# Snowflake internally generates:
#   - storage_aws_iam_user_arn  → used in IAM trust policy
#   - storage_aws_external_id   → used as condition in trust policy
# Both are exposed as outputs for the root module trust patch.
# ─────────────────────────────────────────────────────────────
resource "snowflake_storage_integration" "s3" {
  name    = "${var.database_name}_S3_INTEGRATION_S3"
  type    = "EXTERNAL_STAGE"
  enabled = true

  storage_provider          = "S3"
  storage_aws_role_arn      = var.snowflake_s3_role_arn
  storage_allowed_locations = ["s3://${var.destination_bucket_name}/"]
}

# ─────────────────────────────────────────────────────────────
# EXTERNAL STAGE
# Named pointer to the raw/ prefix in the data lake S3 bucket.
# Snowflake uses this in COPY INTO commands to load parquet
# files from S3 into the RAW_SUPPLYCHAIN schema tables.
# ─────────────────────────────────────────────────────────────
resource "snowflake_stage" "s3_raw" {
  name                = "S3_RAW_STAGE_S3"
  database            = snowflake_database.supplychain_DATABASE.name
  schema              = snowflake_schema.raw_SUPPLYCHAIN.name
  url                 = "s3://${var.destination_bucket_name}/raw/"
  storage_integration = snowflake_storage_integration.s3.name
  file_format         = "TYPE = PARQUET"
  comment             = "External stage pointing to raw S3 data lake — used for COPY INTO"
}