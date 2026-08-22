terraform {
  required_version = ">= 1.11"

  backend "s3" {
    bucket       = "skyrunna-terraform-state-2026"
    key          = "prod/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "skyrunna"
}