terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = "eu-central-1"
  profile = "skywatch-terraform"

  default_tags {
    tags = {
      Project   = "SkyWatch"
      ManagedBy = "Terraform"
    }
  }
}
