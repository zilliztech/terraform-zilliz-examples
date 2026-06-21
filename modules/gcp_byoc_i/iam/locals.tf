locals {
  sa_prefix          = trimsuffix(substr(var.prefix_name, 0, 18), "-")
  gke_node_sa_name   = var.gke_node_service_account_name != "" ? var.gke_node_service_account_name : "${local.sa_prefix}-node"
  management_sa_name = var.management_service_account_name != "" ? var.management_service_account_name : "${local.sa_prefix}-maintenance"
  storage_sa_name    = var.storage_service_account_name != "" ? var.storage_service_account_name : "${local.sa_prefix}-storage"
  booter_sa_name     = var.booter_service_account_name != "" ? var.booter_service_account_name : "${local.sa_prefix}-booter"
  role_suffix_raw    = replace(title(replace(var.prefix_name, "-", " ")), " ", "")
  role_suffix        = substr(local.role_suffix_raw, 0, 20)
}
