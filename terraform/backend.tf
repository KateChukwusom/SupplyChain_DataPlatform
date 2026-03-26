# terraform {
#   backend "s3" {
#     bucket       = "my-prod-tf-state-unique-id" # Same name as above
#     key          = "prod/terraform.tfstate"
#     region       = "us-east-1"
#     use_lockfile = true # Uses S3's native locking (No DynamoDB needed)
#   }
# }
