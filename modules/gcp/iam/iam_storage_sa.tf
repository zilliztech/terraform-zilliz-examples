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
