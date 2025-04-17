terraform {
  backend "s3" {
    bucket       = "ig-platsec-tfstate"
    key          = "terraform/sandbox/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
    encrypt      = true
  }
}