# VPC Module
module "vpc" {
  source = "../../modules/gcp/vpc"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gcp_vpc_name   = var.customer_vpc_name
  gcp_vpc_cidr   = var.gcp_vpc_cidr
  gcp_zones      = var.gcp_zones

  primary_subnet = {
    name = var.customer_primary_subnet_name
    cidr = var.customer_primary_subnet_cidr
  }

  pod_subnet = {
    name = var.customer_pod_subnet_name
    cidr = var.customer_pod_subnet_cidr
  }

  service_subnet = {
    name = var.customer_service_subnet_name
    cidr = var.customer_service_subnet_cidr
  }

  lb_subnet = {
    name = var.customer_lb_subnet_name
    cidr = var.customer_lb_subnet_cidr
  }
}


# GCS Module
module "gcs" {
  source = "../../modules/gcp/gcs"

  gcp_project_id      = var.gcp_project_id
  gcp_region          = var.gcp_region
  storage_bucket_name = local.bucket_name
}

module "private_link" {
  count               = var.enable_private_link ? 1 : 0
  source              = "../../modules/gcp/private-link"
  depends_on          = [module.vpc]
  gcp_project_id      = var.gcp_project_id
  gcp_region          = var.gcp_region
  gcp_vpc_name        = module.vpc.gcp_vpc_name
  service_subnet_name = module.vpc.primary_subnet_name
  prefix_name         = local.prefix_name
}

# # IAM Module
module "iam" {
  source                          = "../../modules/gcp/iam"
  gcp_project_id                  = var.gcp_project_id
  gcp_region                      = var.gcp_region
  gcp_zones                       = var.gcp_zones
  storage_bucket_name             = local.bucket_name
  gke_cluster_name                = local.customer_gke_cluster_name
  storage_service_account_name    = local.customer_storage_service_account_name
  management_service_account_name = local.customer_management_service_account_name
  gke_node_service_account_name   = local.customer_gke_node_service_account_name
  delegate_from                   = var.zilliz_service_account
}
