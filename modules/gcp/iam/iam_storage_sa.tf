resource "google_service_account" "storage-sa" {
  account_id   = var.storage_service_account_name
  display_name = "Zilliz storage service account"
  project      = var.gcp_project_id
  
}

resource "google_project_iam_member" "storage-object-admin-binding" {
  project = var.gcp_project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.storage-sa.email}"
  
  condition {
    title       = "zilliz_byoc_gcs_object_admin"
    description = "zilliz byoc gcs object admin for gcs bucket"
    expression  = "resource.name.startsWith(\"projects/_/buckets/${var.storage_bucket_name}\")"
  }
}

resource "google_project_iam_member" "storage-bucket-viewer-binding" {
  project = var.gcp_project_id
  role    = "roles/storage.bucketViewer"
  member  = "serviceAccount:${google_service_account.storage-sa.email}"
  
  condition {
    title       = "zilliz_byoc_gcs_bucket_viewer"
    description = "zilliz byoc gcs bucket viewer for gcs bucket"
    expression  = "resource.name.startsWith(\"projects/_/buckets/${var.storage_bucket_name}\")"
  }
}

resource "google_iam_workload_identity_pool" "gke_pool" {
  workload_identity_pool_id = "${var.gcp_project_id}-${random_id.short_uuid.hex}"
  display_name              = "GKE Workload Identity Pool"
  description              = "Identity pool for GKE workload identity"
  project                  = var.gcp_project_id
}

resource "google_service_account_iam_member" "cluster-workload-identity" {
  service_account_id = google_service_account.storage-sa.name
  role    = "roles/iam.workloadIdentityUser"
  member  = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.gke_pool.workload_identity_pool_id}/kubernetes.cluster/https://container.googleapis.com/v1/projects/${var.gcp_project_id}/locations/${var.gcp_region}/clusters/${var.gke_cluster_name}"
}