# The <gcp_project_id>.svc.id.goog Workload Identity pool is created implicitly by
# GKE when the first Workload Identity enabled cluster exists in the project. These
# bindings therefore live outside the iam module so the caller can order them after
# the cluster; binding them earlier fails with "Identity Pool does not exist".

resource "google_service_account_iam_member" "storage_workload_identity" {
  for_each = var.manage_iam ? {
    for ksa in var.storage_workload_identity_ksas :
    "${ksa.namespace}/${ksa.name}" => ksa
  } : {}

  service_account_id = var.storage_sa_name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[${each.value.namespace}/${each.value.name}]"
}

resource "google_service_account_iam_member" "management_workload_identity" {
  for_each = var.manage_iam ? {
    for ksa in var.management_workload_identity_ksas :
    "${ksa.namespace}/${ksa.name}" => ksa
  } : {}

  service_account_id = var.management_sa_name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[${each.value.namespace}/${each.value.name}]"
}

resource "google_service_account_iam_member" "storage_workload_identity_cluster" {
  count = var.manage_iam ? 1 : 0

  service_account_id = var.storage_sa_name
  role               = "roles/iam.workloadIdentityUser"
  member             = local.storage_cluster_workload_identity_member
}
