locals {
  required_project_services = toset(concat([
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "storage.googleapis.com",
    ], var.enable_pd_kms || var.enable_gcs_kms || var.enable_gke_secrets_encryption ? ["cloudkms.googleapis.com"] : [],
  var.gke_binary_authorization_evaluation_mode != "" ? ["binaryauthorization.googleapis.com"] : []))
}

# Keep this API separate so project metadata reads do not wait on unrelated APIs.
resource "google_project_service" "cloud_resource_manager" {
  project = var.gcp_project_id
  service = "cloudresourcemanager.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "required" {
  for_each = local.required_project_services

  project = var.gcp_project_id
  service = each.key

  disable_on_destroy = false

  depends_on = [google_project_service.cloud_resource_manager]
}
