locals {
  required_project_services = toset(concat([
    "cloudresourcemanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "storage.googleapis.com",
  ], var.enable_gcs_kms ? ["cloudkms.googleapis.com"] : []))
}

resource "google_project_service" "required" {
  for_each = local.required_project_services

  project = var.gcp_project_id
  service = each.key

  disable_on_destroy = false
}
