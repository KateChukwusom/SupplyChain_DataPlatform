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
# MODULE: S3

module "s3" {
  source = "./modules/s3"

  destination_bucket_name = var.destination_bucket_name
  project_name            = var.project_name
  airbyte_workspace_id    = var.airbyte_workspace_id

  # These come from Snowflake module outputs 
  snowflake_iam_user_arn = module.snowflake.storage_aws_iam_user_arn
  snowflake_external_id  = module.snowflake.storage_aws_external_id
}

# MODULE: SNOWFLAKE
# Creates database, schemas, warehouse, storage integration, and stage.

module "snowflake" {
  source = "./modules/snowflake"

  database_name           = var.snowflake_database
  warehouse_name          = var.snowflake_warehouse
  snowflake_s3_role_arn   = module.s3.snowflake_role_arn
  destination_bucket_name = module.s3.destination_bucket_name
}

# MODULE: AIRBYTE
# Creates sources, destination, and connections.
# Source bucket already exists — Terraform only manages the destination bucket.

module "airbyte" {
  source = "./modules/airbyte"

  airbyte_workspace_id    = var.airbyte_workspace_id
  source_bucket_name      = var.source_bucket_name
  destination_bucket_name = module.s3.destination_bucket_name
  aws_region              = var.aws_region
  airbyte_role_arn        = module.s3.airbyte_role_arn


  postgres_host     = data.aws_ssm_parameter.postgres_host.value
  postgres_port     = data.aws_ssm_parameter.postgres_port.value
  postgres_database = data.aws_ssm_parameter.postgres_dbname.value
  postgres_username = data.aws_ssm_parameter.postgres_username.value
  postgres_password = data.aws_ssm_parameter.postgres_password.value
}