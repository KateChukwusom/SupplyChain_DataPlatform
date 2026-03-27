terraform {
  backend "s3" {
    bucket       = "supply-chain-terraform-state-dekate"
    key          = "prod/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
