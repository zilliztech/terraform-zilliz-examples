# https://www.terraform.io/language/settings/backends/gcs
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.32.0"
    }
  }
}
