# SNOWFLAKE MODULE
# Creates all core Snowflake infrastructure:
#   - Warehouse, Database, Schemas (RAW, STAGING, INTERMEDIATE, MARTS), Storage Integration (secure S3 access via IAM role)
#   - External Stage (to be used in COPY INTO)

# SNOWFLAKE DATABASE
terraform {
  required_providers {
    snowflake = {
      source = "snowflakedb/snowflake"
    }
  }
}



resource "snowflake_database" "supplychain_DATABASE" {
  name = var.database_name
}


# SCHEMA: RAW
#External stage pointing to S3 data lake - COPY INTO reads from here to load RAW schema"
resource "snowflake_schema" "raw_SUPPLYCHAIN" {
  database = snowflake_database.supplychain_DATABASE.name
  name     = "RAW_SUPPLYCHAIN"
}

# dbt staging models lives here
resource "snowflake_schema" "staging_SUPPLYCHAIN" {
  database = snowflake_database.supplychain_DATABASE.name
  name     = "STAGING_SUPPLYCHAIN"
}

#dbt intermediate models lives here
resource "snowflake_schema" "intermediate_SUPPLYCHAIN" {
  database = snowflake_database.supplychain_DATABASE.name
  name     = "INTERMEDIATE_SUPPLYCHAIN"
}

resource "snowflake_schema" "marts_SUPPLYCHAIN" {
  database = snowflake_database.supplychain_DATABASE.name
  name     = "MARTS_SUPPLYCHAIN"
}

# WAREHOUSE- Supply chain data platform compute warehouse

resource "snowflake_warehouse" "supplychain" {
  name           = var.warehouse_name
  warehouse_size = "XSMALL"
  auto_suspend   = 60
  auto_resume    = true

}

#STORAGE INTEGRATION

resource "snowflake_storage_integration" "s3" {
  name    = "${var.database_name}_S3_INTEGRATION"
  type    = "EXTERNAL_STAGE"
  enabled = true

  storage_provider     = "S3"
  storage_aws_role_arn = var.snowflake_s3_role_arn

  storage_allowed_locations = ["s3://${var.destination_bucket_name}/"]
}

# EXTERNAL STAGE
# file_format = PARQUET because Airbyte writes parquet files to S3.

resource "snowflake_stage" "s3_raw" {
  name                = "S3_RAW_STAGE"
  database            = snowflake_database.supplychain_DATABASE.name
  schema              = snowflake_schema.raw_SUPPLYCHAIN.name
  url                 = "s3://${var.destination_bucket_name}/raw/"
  storage_integration = snowflake_storage_integration.s3.name

  file_format = "TYPE = PARQUET"

  comment = "External stage pointing to raw S3 data lake - used for COPY INTO"
}