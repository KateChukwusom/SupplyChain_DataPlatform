terraform {
  backend "s3" {
    bucket       = "supply-chain-terraform-state-de-kate"
    key          = "dekate/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}
