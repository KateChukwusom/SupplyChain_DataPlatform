
#This is to create a storage file which is s3 bucket for storing terraform state file
resource "aws_s3_bucket" "terraform_state" {
  bucket = "supply-chain-terraform-state-dekate" 
  lifecycle {
    prevent_destroy = false 
  }
}

#Enabled versioning to keep history of state file at rest
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}


