# S3 MODULE
# Responsibility 1: Create the data lake S3 bucket
# Responsibility 2: Create Snowflake IAM role with placeholder trust policy
#                   Root module patches the real trust policy after
#                   Snowflake storage integration returns its ARN + external ID

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      
    }
  }
}

# ─────────────────────────────────────────────────────────────
# DATA LAKE S3 BUCKET
# ─────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "data_lake" {
  
  bucket = var.destination_bucket_name

  tags = {
    Name      = var.destination_bucket_name
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "data_lake" {
  
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "data_lake" {
  
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─────────────────────────────────────────────────────────────
# SNOWFLAKE IAM ROLE
# Starts with a Deny placeholder trust policy.
# Root module overwrites it with the real Snowflake principal
# after the storage integration is created.
# ─────────────────────────────────────────────────────────────
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "snowflake_s3_role" {
  name = "${var.project_name}-snowflake-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name      = "${var.project_name}-snowflake-s3-role"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

resource "aws_iam_policy" "snowflake_s3_policy" {
  name        = "${var.project_name}-snowflake-s3-policy"
  description = "Allows Snowflake to read parquet files from the data lake"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.data_lake.arn,
          "${aws_s3_bucket.data_lake.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "snowflake_s3" {
  role       = aws_iam_role.snowflake_s3_role.name
  policy_arn = aws_iam_policy.snowflake_s3_policy.arn
}