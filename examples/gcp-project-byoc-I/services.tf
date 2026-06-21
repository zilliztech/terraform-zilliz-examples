locals {
  required_project_services = toset([
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "storage.googleapis.com",
  ])
}

resource "google_project_service" "required" {
  for_each = local.required_project_services

  project = var.gcp_project_id
  service = each.key

  disable_on_destroy = false
}
