terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.32.0"
    }
    zillizcloud = {
      source  = "zilliztech/zillizcloud"
      version = ">= 0.6.27"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
}

provider "zillizcloud" {
}
