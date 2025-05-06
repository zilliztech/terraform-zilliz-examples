resource "google_service_account" "management-sa" {
  account_id   = var.management_service_account_name
  display_name = "Zilliz management service account"
  project      = var.gcp_project_id
  
}

// Role 1: To be able to manage a cluster. https://cloud.google.com/iam/docs/understanding-roles#container.clusterAdmin
resource "google_project_iam_member" "management-container-binding" {
  project = var.gcp_project_id
  role    = "roles/container.clusterAdmin"
  member  = "serviceAccount:${google_service_account.management-sa.email}"
}

// Role 2: To be able to read the bucket. https://cloud.google.com/iam/docs/understanding-roles#storage.bucketViewer
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

// Role 3: To be able to get the instance group manager. https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountUser
// Generate a random id to avoid role id collision. GCP custom roles have soft-delete behavior, whose name remains locked for 30 more days. During this period, creating a role with the same name may cause confusing behavior between undelete and update operations.
resource "random_id" "short_uuid" {
  byte_length = 3 
}

resource "google_project_iam_custom_role" "zilliz-byoc-gke-minimum-additional-role" {
  role_id     = "zillizByocGkeMinimumAdditionalRole${random_id.short_uuid.hex}"
  title       = "Zilliz BYOC GKE Minimum Additional Role"
  description = "Custom role for Zilliz BYOC with minimum required permissions for GKE node management"
  permissions = [
    "compute.instanceGroupManagers.get"
  ]
  project = var.gcp_project_id
}

resource "google_project_iam_member" "management-gke-minimum-additional-role-binding" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.zilliz-byoc-gke-minimum-additional-role.id
  member  = "serviceAccount:${google_service_account.management-sa.email}"
  
  condition {
    title       = "zilliz_byoc_gke_minimum"
    description = "zilliz byoc gke minimum permissions"
    expression  = join(" || ", [for zone in var.gcp_zones : "resource.name.startsWith(\"projects/${var.gcp_project_id}/zones/${zone}/instanceGroupManagers/gke-${var.gke_cluster_name}\")"])
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