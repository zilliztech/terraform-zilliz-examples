resource "google_service_account" "cross-acount-sa" {
  account_id   = var.cross-acount_service_account_name
  display_name = "Zilliz cross-acount service account"
  project      = var.gcp_project_id

}

// Role 1: To be able to manage a cluster. https://cloud.google.com/iam/docs/understanding-roles#container.clusterAdmin
resource "google_project_iam_member" "cross-acount-container-binding" {
  project = var.gcp_project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.cross-acount-sa.email}"
}

// Role 2: To be able to read the bucket. https://cloud.google.com/iam/docs/understanding-roles#storage.bucketViewer
resource "google_project_iam_member" "cross-acount-storage-binding" {
  project = var.gcp_project_id
  role    = "roles/storage.bucketViewer"
  member  = "serviceAccount:${google_service_account.cross-acount-sa.email}"

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

resource "google_project_iam_custom_role" "igm_custom_role" {
  role_id     = "zillizByocGkeMinimumAdditionalRole${random_id.short_uuid.hex}"
  title       = "Zilliz BYOC GKE Minimum Additional Role"
  description = "Custom role for Zilliz BYOC with minimum required permissions for GKE node cross-acount"
  permissions = [
    "compute.instanceGroupManagers.get",
    "compute.instanceGroupManagers.update",
  ]
  project = var.gcp_project_id
}

resource "google_project_iam_member" "igm_custom_role_binding" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.igm_custom_role.id
  member  = "serviceAccount:${google_service_account.cross-acount-sa.email}"

  condition {
    title       = "zilliz_byoc_gke_minimum"
    description = "zilliz byoc gke minimum permissions"
    expression  = <<-EOT
      resource.name.extract("projects/{name}").startsWith("${var.gcp_project_id}") &&
      resource.name.extract("zones/{name}").startsWith("${var.gcp_region}") &&
      resource.name.extract("instanceGroupManagers/{name}").startsWith("gke-${var.gke_cluster_name}")
    EOT
  }
}

// Role 4: Allow cross-acount service account to use the gke node service account. https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountUser
resource "google_service_account_iam_member" "cross-acount-gke-node-binding" {
  service_account_id = google_service_account.gke-node-sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cross-acount-sa.email}"
}

# Allow zilliz service account to impersonate customer service account
resource "google_service_account_iam_binding" "impersonate" {
  service_account_id = google_service_account.cross-acount-sa.name
  role               = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:${var.delegate_from}"
  ]
}

// custom role to set iam policy on service account
resource "google_project_iam_custom_role" "service_account_policy_admin" {
  role_id = "serviceAccountPolicyAdmin${random_id.short_uuid.hex}"
  title   = "Service Account Policy Admin"
  permissions = [
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.setIamPolicy"
  ]
  project = var.gcp_project_id
  stage   = "GA"
}

# Allow the cross-account service account to grant or revoke the roles/iam.workloadIdentityUser role on the storage service account.
# This is achieved by assigning the custom "Service Account Policy Admin" role to the cross-account SA for the storage SA, with a highly restrictive condition:
# - Principal: The cross-account service account.
# - Role: The custom "Service Account Policy Admin".
# - Resource: The storage service account.
# - Condition: The expression api.getAttribute("iam.googleapis.com/modifiedGrantsByRole", []).hasOnly(["roles/iam.workloadIdentityUser"]) strictly limits the setIamPolicy permission.
#   This ensures the cross-account SA can only manage the roles/iam.workloadIdentityUser role on the storage SA, preventing privilege escalation by disallowing assignment of any other roles.
resource "google_service_account_iam_member" "service_account_policy_admin_role_binding" {
  service_account_id = google_service_account.storage-sa.name
  role               = google_project_iam_custom_role.service_account_policy_admin.id
  member             = "serviceAccount:${google_service_account.cross-acount-sa.email}"

  condition {
    title       = "LimitedRoleGranting"
    description = "Can only grant workload identity user role"
    expression  = "api.getAttribute(\"iam.googleapis.com/modifiedGrantsByRole\", []).hasOnly([\"roles/iam.workloadIdentityUser\"])"
  }
}


# Its job is to fetch information about an existing resource
# in this case, the project's default Compute Engine service account. 
# This account is automatically created by Google Cloud and has the email format <project_number>-compute@developer.gserviceaccount.com.
data "google_compute_default_service_account" "default" {
}

// Grants the cross-acount service account the ability to impersonate 
// the default compute service account( <project_number>-compute@developer.gserviceaccount.com)
// This is required for the cross-acount service account to perform creating gke on behalf of the default service account
resource "google_service_account_iam_member" "cross-acount-default-sa-binding" {
  service_account_id = data.google_compute_default_service_account.default.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cross-acount-sa.email}"
}