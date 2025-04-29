
module "private_link" {
  source = "../../modules/gcp/private-link"

  gcp_project_id      = var.gcp_project_id
  gcp_region          = var.gcp_region
  gcp_vpc_name        = var.gcp_vpc_name
  service_subnet_name = var.primary_subnet_name
  prefix_name         = var.k8s_short_cluster_name
}

# IAM Module
module "iam" {
  source                          = "../../modules/gcp/iam"
  gcp_project_id                  = var.gcp_project_id
  gcp_region                      = var.gcp_region
  storage_service_account_name    = var.storage_service_account_name
  storage_bucket_name             = var.storage_bucket_name
  gke_cluster_name                = var.k8s_short_cluster_name
  management_service_account_name = var.management_service_account_name
  gke_node_service_account_name   = var.gke_node_service_account_name
  delegate_from                   = var.delegate_from
}

output "iam_module_output" {
  value = module.iam
}

output "private_link_module_output" {
  value = module.private_link
}
