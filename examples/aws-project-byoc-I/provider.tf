terraform {
  required_version = ">=1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.89.0"
    }
    zillizcloud = {
      source  = "zilliztech/zillizcloud"
      version = "~> 0.6.46"
    }
  }
}

provider "aws" {
  region = local.region
}

provider "zillizcloud" {
  host_address = upper(trimspace(var.env)) == "UAT" ? "https://api.cloud-uat3.zilliz.com/v2" : "https://api.cloud.zilliz.com/v2"
}
