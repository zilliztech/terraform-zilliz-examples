locals {
  sa_prefix          = trimsuffix(substr(var.prefix_name, 0, 18), "-")
  gke_node_sa_name   = var.gke_node_service_account_name != "" ? var.gke_node_service_account_name : "${local.sa_prefix}-node"
  management_sa_name = var.management_service_account_name != "" ? var.management_service_account_name : "${local.sa_prefix}-maintenance"
  storage_sa_name    = var.storage_service_account_name != "" ? var.storage_service_account_name : "${local.sa_prefix}-storage"
  booter_sa_name     = var.booter_service_account_name != "" ? var.booter_service_account_name : "${local.sa_prefix}-booter"
  role_suffix_raw    = replace(title(replace(var.prefix_name, "-", " ")), " ", "")
  role_suffix        = substr(local.role_suffix_raw, 0, 20)

  storage_cluster_workload_identity_member = "principalSet://iam.googleapis.com/projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${var.gcp_project_id}.svc.id.goog/kubernetes.cluster/https://container.googleapis.com/v1/projects/${var.gcp_project_id}/locations/${var.gke_location}/clusters/${var.gke_cluster_name}"

  booter_self_delete_condition = (
    var.enable_resource_manager_tags
    ? "resource.type == \"compute.googleapis.com/Instance\" && resource.name == \"projects/${var.gcp_project_id}/zones/${var.booter_zone}/instances/${var.booter_instance_name}\" && resource.matchTagId(\"${var.vendor_tag_key_id}\", \"${var.vendor_tag_value_id}\")"
    : "resource.type == \"compute.googleapis.com/Instance\" && resource.name == \"projects/${var.gcp_project_id}/zones/${var.booter_zone}/instances/${var.booter_instance_name}\""
  )
}
