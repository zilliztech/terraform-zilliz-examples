# https://www.terraform.io/language/settings/backends/gcs
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.32.0"
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  impersonate_service_account = var.gke_cross-acount_sa
}