# AIRBYTE MODULE
# Creates:
#   - 3 Sources: S3, Postgres - 1 Destination: S3 (parquet format — supplychain data lake)
#   - 3 Connections: each source → S3 destination

# SOURCE: S3
# Reads the 4 datasets already sitting in the S3 bucket:
# format = parquet because the files are already parquet.
terraform {
  required_providers {
    airbyte = {
      source = "airbytehq/airbyte"
    }
  }
}
resource "airbyte_source" "s3" {
  name         = "s3-supplychain-source"
  workspace_id = var.airbyte_workspace_id

  configuration = jsonencode({
    bucket      = var.source_bucket_name
    region_name = var.aws_region
    role_arn    = var.airbyte_role_arn

    streams = [
      {
        name   = "inventory"
        format = { filetype = "parquet" }
        globs  = ["raw/inventory/*.parquet"]
      },
      {
        name   = "suppliers"
        format = { filetype = "parquet" }
        globs  = ["raw/suppliers/*.parquet"]
      },
      {
        name   = "products"
        format = { filetype = "parquet" }
        globs  = ["raw/products/*.parquet"]
      },
      {
        name   = "warehouses"
        format = { filetype = "parquet" }
        globs  = ["raw/warehouses/*.parquet"]
      }
    ]
  })
}

# SOURCE: POSTGRES

resource "airbyte_source" "postgres" {
  name         = "postgres-supplychain-source"
  workspace_id = var.airbyte_workspace_id

  configuration = jsonencode({
    host     = var.postgres_host
    port     = var.postgres_port
    database = var.postgres_database
    username = var.postgres_username
    password = var.postgres_password
    schemas  = ["public"]

    replication_method = {
      method = "scan_changes_with_user_defined_cursor"
      streams = [
        {
          name                  = "sales"
          sync_mode             = "incremental_deduped_history"
          destination_sync_mode = "append_dedup"
          cursor_field          = ["updated_at"]
          primary_key           = [["id"]]
        }
      ]
    }
  })
}


# DESTINATION: S3
# All sources write to this single S3 destination as parquet files.
# s3_bucket_path = "raw" means data lands under s3://your-bucket/raw/
# format = PARQUET with SNAPPY compression.

resource "airbyte_destination" "s3" {
  name         = "s3-data-lake-destination"
  workspace_id = var.airbyte_workspace_id

  configuration = jsonencode({
    s3_bucket_name   = var.destination_bucket_name
    s3_bucket_region = var.aws_region
    s3_bucket_path   = "raw"

    credential = {
      credential_type = "Role Based Authentication"
      role_arn        = var.airbyte_role_arn
    }

    format = {
      format_type       = "Parquet"
      compression_codec = "SNAPPY"
    }
  })
}

# -----------------------------------------------------------------------------
# CONNECTION: S3 SOURCE → S3 DESTINATION

resource "airbyte_connection" "s3_to_lake" {
  name           = "s3-source-to-data-lake"
  source_id      = airbyte_source.s3.source_id
  destination_id = airbyte_destination.s3.destination_id

  schedule = {
    schedule_type = "manual"
  }

  configurations = {
    streams = [
      {
        name      = "inventory"
        sync_mode = "full_refresh_overwrite"
      },
      {
        name      = "suppliers"
        sync_mode = "full_refresh_overwrite"
      },
      {
        name      = "products"
        sync_mode = "full_refresh_overwrite"
      },
      {
        name      = "warehouses"
        sync_mode = "full_refresh_overwrite"
      }
    ]
  }

  status = "active"
}

# -----------------------------------------------------------------------------
# CONNECTION: POSTGRES → S3 DESTINATION

resource "airbyte_connection" "postgres_to_lake" {
  name           = "postgres-source-to-data-lake"
  source_id      = airbyte_source.postgres.source_id
  destination_id = airbyte_destination.s3.destination_id

  schedule = {
    schedule_type = "manual"
  }

  configurations = {
    streams = [
      {
        name      = "sales"
        sync_mode = "incremental_append"
      }
    ]
  }

  status = "active"
}
