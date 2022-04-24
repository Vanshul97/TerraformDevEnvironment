terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region                   = "us-west-2"
  profile                  = "VSCode"
  shared_credentials_files = ["~/.aws/credentials"]
}

