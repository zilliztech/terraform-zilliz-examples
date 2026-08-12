data "google_container_cluster" "existing" {
  count = local.create_cluster ? 0 : 1

  project  = var.gcp_project_id
  name     = var.cluster_name
  location = var.gcp_region
}
