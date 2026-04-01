# ─────────────────────────────────────────────────────────────
# AIRBYTE
# ─────────────────────────────────────────────────────────────
variable "airbyte_workspace_id" {
  description = "Airbyte Cloud workspace ID"
  type        = string
}

# ─────────────────────────────────────────────────────────────
# SOURCE S3
# ─────────────────────────────────────────────────────────────
variable "source_bucket_name" {
  description = "Name of the existing source S3 bucket where raw files live"
  type        = string
}

variable "source_aws_access_key_id" {
  description = "AWS access key for reading from source S3 bucket"
  type        = string
  sensitive   = true
}

variable "source_aws_secret_access_key" {
  description = "AWS secret key for reading from source S3 bucket"
  type        = string
  sensitive   = true
}

# ─────────────────────────────────────────────────────────────
# DESTINATION S3 (Data Lake)
# ─────────────────────────────────────────────────────────────
variable "destination_bucket_name" {
  description = "Name of the data lake S3 bucket Airbyte writes to"
  type        = string
}

variable "datalake_aws_access_key_id" {
  description = "AWS access key for writing to data lake S3 bucket"
  type        = string
  sensitive   = true
}

variable "datalake_aws_secret_access_key" {
  description = "AWS secret key for writing to data lake S3 bucket"
  type        = string
  sensitive   = true
}


variable "aws_region" {
  description = "AWS region for the destination S3 bucket"
  type        = string
}
# ─────────────────────────────────────────────────────────────
# POSTGRES
# ─────────────────────────────────────────────────────────────
variable "postgres_host" {
  description = "Hostname of Postgres database"
  type        = string
  sensitive   = true
}

variable "postgres_port" {
  description = "Port of Postgres database"
  type        = string
  default     = "6543"
}

variable "postgres_database" {
  description = "Name of Postgres database"
  type        = string
}

variable "postgres_username" {
  description = "Username for Postgres database"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "Password for Postgres database"
  type        = string
  sensitive   = true
}