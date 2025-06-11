# VPC Module
//random id
resource "random_id" "short_uuid" {
  byte_length = 3 # 3 bytes = 6 characters when base64 encoded
}
locals {
  bucket_name                              = var.customer_bucket_name != "" ? var.customer_bucket_name : "${var.customer_vpc_name}-bucket-${random_id.short_uuid.hex}"
  prefix_name                              = var.customer_vpc_name
  customer_gke_cluster_name                = var.customer_gke_cluster_name != "" ? var.customer_gke_cluster_name : "${var.customer_vpc_name}-gke"
  customer_storage_service_account_name    = var.customer_storage_service_account_name != "" ? var.customer_storage_service_account_name : "${var.customer_vpc_name}-storage-sa"
  customer_cross-account_service_account_name = var.customer_cross-account_service_account_name != "" ? var.customer_cross-account_service_account_name : "${var.customer_vpc_name}-cross-account-sa"
  customer_gke_node_service_account_name   = var.customer_gke_node_service_account_name != "" ? var.customer_gke_node_service_account_name : "${var.customer_vpc_name}-gke-node-sa"
}

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
  cross-acount_service_account_name = local.customer_cross-account_service_account_name
  gke_node_service_account_name   = local.customer_gke_node_service_account_name
  delegate_from                   = var.zilliz_service_account
}



output "output" {
  value = {
    "1.Google Cloud Platform Project ID" = var.gcp_project_id
    "2.Storage Settings" = {
      "1.GCS Bucket Name" = local.bucket_name
      "2.Service Account Email" = module.iam.storage_service_account_email
    }
    "3.GKE Settings" = {
      "1.GKE Cluster Name" = local.customer_gke_cluster_name
      "2.GKE Node Service Account Name" = module.iam.gke_service_account_email
    }
    "4.Cross-Account Settings" = {
      "1.Service Account Email" = module.iam.cross_project_service_account_email
    }
    "5.VPC Settings" = {
      "1.VPC Name" = module.vpc.gcp_vpc_name
      "2.Primary Subnet Name" = module.vpc.primary_subnet_name
      "3.Secondary Subnet Range Name(Pods)" = module.vpc.secondary_subnet_range_name_pods
      "4.Secondary Subnet Range Name(Services)" = module.vpc.secondary_subnet_range_name_services
      "5.Load Balance Subnet Name" = module.vpc.load_balancer_subnet_name
      "6.Private Service Connect" = var.enable_private_link ? module.private_link[0].byoc_endpoint_ip : null
    }
  }
}
