terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.32.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# VPC Module
module "vpc" {
  source = "../../modules/gcp/vpc"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gcp_vpc_name   = var.gcp_vpc_name
  gcp_vpc_cidr   = var.gcp_vpc_cidr
  gcp_zones      = var.gcp_zones

  primary_subnet = {
    name = var.primary_subnet_name
    cidr = var.primary_subnet_cidr
  }

  pod_subnet = {
    name = var.pod_subnet_name
    cidr = var.pod_subnet_cidr
  }

  service_subnet = {
    name = var.service_subnet_name
    cidr = var.service_subnet_cidr
  }

  lb_subnet = {
    name = var.lb_subnet_name
    cidr = var.lb_subnet_cidr
  }
}

# # GCS Module
module "gcs" {
  source = "../../modules/gcp/gcs"

  gcp_project_id      = var.gcp_project_id
  gcp_region          = var.gcp_region
  storage_bucket_name = var.storage_bucket_name
}

# # GKE Module

