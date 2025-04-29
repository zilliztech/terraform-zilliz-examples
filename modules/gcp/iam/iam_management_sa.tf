resource "google_service_account" "management-sa" {
  account_id   = var.management_service_account_name
  display_name = "Zilliz management service account"
  project      = var.gcp_project_id
  
}

resource "google_project_iam_member" "management-container-binding" {
  project = var.gcp_project_id
  role    = "roles/container.clusterAdmin"
  member  = "serviceAccount:${google_service_account.management-sa.email}"
  
  condition {
    title       = "zilliz_byoc_cluster_admin"
    description = "zilliz byoc cluster admin for container"
    expression  = "resource.name.startsWith(\"projects/${var.gcp_project_id}/locations/${var.gcp_region}/clusters/${var.gke_cluster_name}\")"
  }
}

resource "google_project_iam_member" "management-storage-binding" {
  project = var.gcp_project_id
  role    = "roles/storage.bucketViewer"
  member  = "serviceAccount:${google_service_account.management-sa.email}"
  
  condition {
    title       = "zilliz_byoc_gcs_bucket_viewer"
    description = "zilliz byoc gcs bucket viewer for gcs bucket"
    expression  = "resource.name.startsWith(\"projects/_/buckets/${var.storage_bucket_name}\")"
  }
}


# Allow zilliz service account to impersonate customer service account
resource "google_service_account_iam_binding" "impersonate" {
  service_account_id = google_service_account.management-sa.name
  role               = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:${var.delegate_from}"
  ]
}

// TODO: impersonate