# Keep project metadata outside the GKE-dependent module so IAM members remain
# known during planning when the cluster or its node pools change.
data "google_project" "this" {
  project_id = var.gcp_project_id

  depends_on = [google_project_service.cloud_resource_manager]
}
