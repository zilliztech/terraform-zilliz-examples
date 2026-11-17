# Keep project metadata outside the GKE-dependent module so IAM members remain
# known during planning when the cluster or its node pools change.
data "google_project" "this" {
  project_id = var.gcp_project_id

  depends_on = [google_project_service.cloud_resource_manager]
}

data "zillizcloud_byoc_vpc_endpoint_service" "this" {
  count = local.enable_private_link && var.gcp_psc_service_attachment_id == "" && local.configured_psc_service_attachment_id == "" ? 1 : 0

  cloud_id = "gcp"
  region   = local.gcp_region
}
