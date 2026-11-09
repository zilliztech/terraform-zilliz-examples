terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.48.0"
    }
    zillizcloud = {
      source  = "zilliztech/zillizcloud"
      version = ">= 0.6.46"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
}

provider "zillizcloud" {
  host_address = upper(trimspace(var.env)) == "UAT" ? "https://api.cloud-uat3.zilliz.com/v2" : "https://api.cloud.zilliz.com/v2"
}
