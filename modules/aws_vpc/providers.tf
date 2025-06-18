terraform {
  required_version = ">=1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.20.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Vendor    = "zilliz-byoc"
    }
  }
}