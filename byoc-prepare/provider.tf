terraform {
  required_version = ">=1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.82.1"
    }
    zillizcloud = {
      source  = "zilliztech/zillizcloud"
      version = "~> 0.3.0"
    }
  }
}

provider "aws" {
  # profile = "byoc"
  region  = var.aws_region
}

provider "zillizcloud" {
    api_key   = "11a7e4709596d0970d36cdb73387205cdf9f151c6ca247208ae0c57dc2173a58abf8e60e3068f5b5bc5e119958be5bc5f30bce2f"
    byoc_mode = true
}
