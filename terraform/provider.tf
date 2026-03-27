provider "aws" {
  region = var.aws_region
}
provider "aws" {
  alias   = "admin_account"
  region  = var.admin_region
  profile = "admin"
}

provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account
  user              = var.snowflake_user
  password          = var.snowflake_password
  role              = var.snowflake_role

  preview_features_enabled = ["snowflake_storage_integration_resource", "snowflake_stage_resource"]
}
provider "airbyte" {
  client_id     = var.airbyte_client_id
  client_secret = var.airbyte_client_secret
}