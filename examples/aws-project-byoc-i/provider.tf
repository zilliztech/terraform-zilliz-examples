terraform {
  required_version = ">=1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.82.1"
      version = ">=5.20.0"
    }
    zillizcloud = {
      source  = "zilliztech/zillizcloud"
      version = "~> 0.4.0"
    }
  }
}

provider "aws" {
}

provider "zillizcloud" {
  host_address = "https://api.cloud-uat3.zilliz.com/v2"
}
