resource "google_service_account" "management-sa" {
  account_id   = var.management_service_account_name
  display_name = "Zilliz management service account"
  project      = var.gcp_project_id
  
}

resource "google_project_iam_member" "management-binding" {
  project = var.gcp_project_id
  role    = "roles/container.clusterAdmin"
  member  = "serviceAccount:${google_service_account.management-sa.email}"
  
  condition {
    title       = "zilliz_byoc_cluster_admin"
    description = "zilliz byoc cluster admin for container"
    expression  = "resource.name.startsWith(\"projects/${var.gcp_project_id}/locations/${var.gcp_region}/clusters/${var.gke_cluster_name}\")"
  }
}

# should after gke cluster created
// TODO: replace with impersonate
resource "google_service_account_iam_member" "management-cluster-workload-identity" {
  service_account_id = google_service_account.management-sa.name
  role    = "roles/iam.workloadIdentityUser"
  member  = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${var.gcp_project_id}.svc.id.goog/kubernetes.cluster/https://container.googleapis.com/v1/projects/${var.gcp_project_id}/locations/${var.gcp_region}/clusters/${var.gke_cluster_name}"
}