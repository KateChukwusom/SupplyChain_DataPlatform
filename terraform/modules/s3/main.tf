
# S3 MODULE
# Creates the data lake bucket and all IAM roles/policies for
# Snowflake (read) and Airbyte (write) to access the bucket securely.
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_s3_bucket" "raw_supplychain_data_DEKate" {
  bucket = var.destination_bucket_name

  tags = {
    Name      = var.destination_bucket_name
    Project   = var.project_name
    ManagedBy = "DE-Kate"
  }
}

#Bucket version to store versions of files stored here
resource "aws_s3_bucket_versioning" "raw_supplychain_data_DEKate" {
  bucket = aws_s3_bucket.raw_supplychain_data_DEKate.id

  versioning_configuration {
    status = "Enabled"
  }
}


# Block public access 
resource "aws_s3_bucket_public_access_block" "raw_supplychain_data" {
  bucket = aws_s3_bucket.raw_supplychain_data_DEKate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SNOWFLAKE IAM ROLE
# Snowflake assumes this role to read parquet files from S3.

resource "aws_iam_role" "snowflake_s3_role" {
  name = "${var.project_name}-snowflake-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.snowflake_iam_user_arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.snowflake_external_id
          }
        }
      }
    ]
  })

  tags = {
    Name      = "${var.project_name}-snowflake-s3-role"
    ManagedBy = "DE-Kate"
  }
}

# SNOWFLAKE IAM POLICY — Snowflake access to s3

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
          aws_s3_bucket.raw_supplychain_data_DEKate.arn,
          "${aws_s3_bucket.raw_supplychain_data_DEKate.arn}/*"
        ]
      }
    ]
  })
}


# ATTACH SNOWFLAKE POLICY TO SNOWFLAKE ROLE

resource "aws_iam_role_policy_attachment" "snowflake_s3" {
  role       = aws_iam_role.snowflake_s3_role.name
  policy_arn = aws_iam_policy.snowflake_s3_policy.arn
}


# for Airbyte Cloud
resource "aws_iam_role" "airbyte_s3_role" {
  name = "${var.project_name}-airbyte-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # Airbyte Cloud's AWS account 
          AWS = "arn:aws:iam::094410056844:user/delegated_access_user"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.airbyte_workspace_id
          }
        }
      }
    ]
  })

  tags = {
    Name      = "${var.project_name}-airbyte-s3-role"
    ManagedBy = "DE-Kate"
  }
}

# AIRBYTE IAM POLICY — what Airbyte can do on S3
#   PutObject              — writes parquet files
#   GetObject              — reads files to verify uploads
#   ListBucket             — checks existing files to avoid duplicates
#   DeleteObject           — cleans up temp files during sync
#   AbortMultipartUpload   — cancels failed large file uploads 
#   ListMultipartUploadParts — tracks progress of large uploads

resource "aws_iam_policy" "airbyte_s3_policy" {
  name        = "${var.project_name}-airbyte-s3-policy"
  description = "Allows Airbyte to write parquet files to the data lake"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.raw_supplychain_data_DEKate.arn,
          "${aws_s3_bucket.raw_supplychain_data_DEKate.arn}/*"
        ]
      }
    ]
  })
}

# ATTACH AIRBYTE POLICY TO AIRBYTE ROLE

resource "aws_iam_role_policy_attachment" "airbyte_s3" {
  role       = aws_iam_role.airbyte_s3_role.name
  policy_arn = aws_iam_policy.airbyte_s3_policy.arn
}

