resource "aws_s3_bucket" "raw_supplychain_data" {
  bucket = "raw-supplychain-data"

  tags = {
    Name        = "Engineer2"
  }
}

resource "aws_s3_bucket_public_access_block" "supplychaindata_access" {
  bucket = aws_s3_bucket.raw_supplychain_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "airbyte-iam-role" {
  name = "airbyte-to-s3"

  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "airbyte"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}