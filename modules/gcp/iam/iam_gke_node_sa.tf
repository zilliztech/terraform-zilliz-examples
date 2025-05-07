resource "google_service_account" "gke-node-sa" {
  account_id   = var.gke_node_service_account_name
  display_name = "Zilliz gke node service account"
  project      = var.gcp_project_id
  
}

resource "google_project_iam_member" "gke-node-binding" {
  project = var.gcp_project_id
  role    = "roles/container.defaultNodeServiceAccount"
  member  = "serviceAccount:${google_service_account.gke-node-sa.email}"
  
  condition {
    title       = "zilliz_byoc_gke_node_service_account"
    description = "zilliz byoc gke node service account for container"
    expression  = "resource.name.startsWith(\"projects/${var.gcp_project_id}/locations/${var.gcp_region}/clusters/${var.gke_cluster_name}\")"
  }
}
