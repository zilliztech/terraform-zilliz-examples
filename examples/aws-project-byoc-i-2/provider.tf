terraform {
  required_version = ">=1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.89.0"
    }
    zillizcloud = {
      source  = "zilliztech/zillizcloud"
      version = "~> 0.4.1"
    }
  }
}

provider "aws" {
}

provider "zillizcloud" {
}
