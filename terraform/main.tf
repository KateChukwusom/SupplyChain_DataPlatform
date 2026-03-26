# provider "aws" {
#   region = "us-east-1" # Your preferred region
# }


# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "my-prod-tf-state-unique-id" # Must be unique globally

#   lifecycle {
#     prevent_destroy = false # Safety: prevents accidental 'terraform destroy'
#   }
# }

# # 2. Versioning (Crucial for Production)
# resource "aws_s3_bucket_versioning" "enabled" {
#   bucket = aws_s3_bucket.terraform_state.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# # 3. Encryption (Keep your state secrets safe)
# resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
#   bucket = aws_s3_bucket.terraform_state.id
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

