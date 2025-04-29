resource "google_service_account" "storage-sa" {
  account_id   = var.storage_service_account_name
  display_name = "Zilliz storage service account"
  project      = var.gcp_project_id
  
}

resource "google_project_iam_member" "storage-binding" {
  project = var.gcp_project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.storage-sa.email}"
  
  condition {
    title       = "zilliz_byoc_gcs_object_admin"
    description = "zilliz byoc gcs object admin for gcs bucket"
    expression  = "resource.name.startsWith(\"projects/_/buckets/${var.storage_bucket_name}\")"
  }
}

# should after gke cluster created
resource "google_service_account_iam_member" "storage-cluster-workload-identity" {
  service_account_id = google_service_account.storage-sa.name
  role    = "roles/iam.workloadIdentityUser"
  member  = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${var.gcp_project_id}.svc.id.goog/kubernetes.cluster/https://container.googleapis.com/v1/projects/${var.gcp_project_id}/locations/${var.gcp_region}/clusters/${var.gke_cluster_name}"
}