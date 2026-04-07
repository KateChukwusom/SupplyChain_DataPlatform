
#This creates the bucket that will hold the .tfstate file for the  project. 
# Every time Terraform runs in the root module, it reads and writes to
# this bucket to know what infrastructure already exists, it 
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


