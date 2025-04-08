terraform {
  required_version = ">=1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.89.0"
    }
    zillizcloud = {
      source  = "zilliztech/zillizcloud"
      version = "~> 0.4.2"
    }
  }
}

provider "aws" {
}

provider "zillizcloud" {
  api_key = "xxx"
  host_address = "http://localhost:8080/v2"
}
