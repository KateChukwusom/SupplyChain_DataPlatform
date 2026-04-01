terraform {
  required_providers {
    airbyte = {
      source = "airbytehq/airbyte"
    }
  }
}

resource "airbyte_source_s3" "s3" {
  name         = "s3-supplychain-source"
  workspace_id = var.airbyte_workspace_id

  configuration = {
    bucket                = var.source_bucket_name
    region_name           = "eu-west-2"
    aws_access_key_id     = var.source_aws_access_key_id
    aws_secret_access_key = var.source_aws_secret_access_key

    streams = [
      {
        name   = "inventory"
        format = { csv_format = {} }
        globs  = ["raw/inventory/*.csv"]
      },
      {
        name   = "suppliers"
        format = { csv_format = {} }
        globs  = ["raw/suppliers/*.csv"]
      },
      {
        name   = "products"
        format = { csv_format = {} }
        globs  = ["raw/products/*.csv"]
      },
      {
        name   = "warehouses"
        format = { csv_format = {} }
        globs  = ["raw/warehouses/*.csv"]
      }
    ]
  }
}

resource "airbyte_source_postgres" "postgres" {
  name         = "postgres-supplychain-source"
  workspace_id = var.airbyte_workspace_id

  configuration = {
    host     = var.postgres_host
    port     = tonumber(var.postgres_port)
    database = var.postgres_database
    username = var.postgres_username
    password = var.postgres_password
    schemas  = ["public"]

    replication_method = {
  method = "scan_changes_with_user_defined_cursor"
  streams = [
    { name = "sales_2026_03_10", cursor_field = ["transaction_timestamp"], primary_key = [["transaction_id"]] },
    { name = "sales_2026_03_11", cursor_field = ["transaction_timestamp"], primary_key = [["transaction_id"]] },
    { name = "sales_2026_03_12", cursor_field = ["transaction_timestamp"], primary_key = [["transaction_id"]] },
    { name = "sales_2026_03_13", cursor_field = ["transaction_timestamp"], primary_key = [["transaction_id"]] },
    { name = "sales_2026_03_14", cursor_field = ["transaction_timestamp"], primary_key = [["transaction_id"]] },
    { name = "sales_2026_03_15", cursor_field = ["transaction_timestamp"], primary_key = [["transaction_id"]] },
    { name = "sales_2026_03_16", cursor_field = ["transaction_timestamp"], primary_key = [["transaction_id"]] },
  ]
}
  }
}

resource "airbyte_destination_s3" "s3" {
  name         = "s3-data-lake-destination"
  workspace_id = var.airbyte_workspace_id

  configuration = {
    s3_bucket_name    = var.destination_bucket_name
    s3_bucket_region  = var.aws_region
    s3_bucket_path    = "raw"
    access_key_id     = var.datalake_aws_access_key_id
    secret_access_key = var.datalake_aws_secret_access_key

    format = {
      parquet_columnar_storage = {
        compression_codec = "SNAPPY"
      }
    }
  }
}

resource "airbyte_connection" "s3_to_lake" {
  name           = "s3-source-to-data-lake"
  source_id      = airbyte_source_s3.s3.source_id
  destination_id = airbyte_destination_s3.s3.destination_id

  schedule = {
    schedule_type = "manual"
  }

  configurations = {
    streams = [
      { name = "inventory", sync_mode = "full_refresh_overwrite" },
      { name = "suppliers", sync_mode = "full_refresh_overwrite" },
      { name = "products",  sync_mode = "full_refresh_overwrite" },
      { name = "warehouses", sync_mode = "full_refresh_overwrite" },
    ]
  }

  status = "active"
}

resource "airbyte_connection" "postgres_to_lake" {
  name           = "postgres-source-to-data-lake"
  source_id      = airbyte_source_postgres.postgres.source_id
  destination_id = airbyte_destination_s3.s3.destination_id

  schedule = {
    schedule_type = "manual"
  }

  configurations = {
    streams = [
      { name = "sales_2026_03_10", sync_mode = "incremental_append", cursor_field = ["transaction_timestamp"], primary_key = [["transaction_id"]] },
      { name = "sales_2026_03_11", sync_mode = "incremental_append", cursor_field = ["transaction_timestamp"], primary_key = [["transaction_id"]] },
      { name = "sales_2026_03_12", sync_mode = "incremental_append", cursor_field = ["transaction_timestamp"], primary_key = [["transaction_id"]] },
      { name = "sales_2026_03_13", sync_mode = "incremental_append", cursor_field = ["transaction_timestamp"], primary_key = [["transaction_id"]] },
      { name = "sales_2026_03_14", sync_mode = "incremental_append", cursor_field = ["transaction_timestamp"], primary_key = [["transaction_id"]] },
      { name = "sales_2026_03_15", sync_mode = "incremental_append", cursor_field = ["transaction_timestamp"], primary_key = [["transaction_id"]] },
      { name = "sales_2026_03_16", sync_mode = "incremental_append", cursor_field = ["transaction_timestamp"], primary_key = [["transaction_id"]] },
    ]
  }

  status = "active"
}