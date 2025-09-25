data "zillizcloud_byoc_i_project_settings" "this" {
  project_id    = var.project_id
  data_plane_id = var.dataplane_id
}
data "zillizcloud_external_id" "current" {}

module "vpc" {
  count = local.is_existing_vpc ? 0 : 1
  source = "../../modules/aws_byoc_i/vpc"
  prefix_name = local.prefix_name
  dataplane_id = local.dataplane_id
  vpc_cidr = var.vpc_cidr
  custom_tags = var.custom_tags
  region = local.region
  enable_endpoint = local.enable_endpoint
}

module "s3" {
  source = "../../modules/aws_byoc_i/s3"
  prefix_name = local.prefix_name
  dataplane_id = local.dataplane_id
  customer_bucket_name = var.customer_bucket_name
  custom_tags = var.custom_tags
}

module "private_link" {
  count = local.enable_private_link? 1: 0
  enable_private_hosted_zone = !var.enable_manual_private_link
  source = "../../modules/aws_byoc_i/privatelink"
  prefix_name = local.prefix_name
  dataplane_id = local.dataplane_id
  region = local.region
  vpc_id = local.vpc_id
  subnet_ids = local.subnet_ids
  security_group_ids = local.private_link_security_group_ids
  custom_tags = var.custom_tags
}

module "eks" {
  source = "../../modules/aws_byoc_i/eks"
  prefix_name = local.prefix_name
  dataplane_id = local.dataplane_id
  region = local.region
  cluster_additional_security_group_ids = local.cluster_additional_security_group_ids
  node_security_group_ids = local.node_security_group_ids
  vpc_id = local.vpc_id
  subnet_ids = local.subnet_ids
  customer_pod_subnet_ids = local.customer_pod_subnet_ids
  eks_control_plane_subnet_ids = local.eks_control_plane_subnet_ids
  external_id = local.external_id
  agent_config = local.agent_config
  enable_private_link = local.enable_private_link
  k8s_node_groups = local.k8s_node_groups
  s3_bucket_id = local.s3_bucket_id
  // eks name
  customer_eks_cluster_name = var.customer_eks_cluster_name
  // role names
  customer_eks_role_name = var.customer_eks_role_name
  customer_eks_addon_role_name = var.customer_eks_addon_role_name
  customer_maintenance_role_name = var.customer_maintenance_role_name
  customer_storage_role_name = var.customer_storage_role_name
  custom_tags = var.custom_tags
  // ecr
  customer_ecr = var.customer_ecr
  booter = var.booter
  // minimal roles configuration
  minimal_roles = var.minimal_roles

  // depend on private link to establish agent tunnel connection
  depends_on = [module.private_link]
}



resource "zillizcloud_byoc_i_project_agent" "this" {
  project_id    = local.project_id
  data_plane_id = local.data_plane_id

  depends_on = [module.eks]
}




resource "zillizcloud_byoc_i_project" "this" {

  project_id    = local.project_id
  data_plane_id = local.data_plane_id

  aws = {
    region = data.zillizcloud_byoc_i_project_settings.this.region

    network = {
      vpc_id             = local.vpc_id
      subnet_ids         = local.subnet_ids
      security_group_ids = []
      vpc_endpoint_id    = local.byoc_endpoint
    }
    role_arn = {
      storage       = local.storage_role.arn
      eks           = local.eks_addon_role.arn
      cross_account = local.maintenance_role.arn
    }
    storage = {
      bucket_id = local.s3_bucket_id
    }
  }

  // depend on private link to establish agent tunnel connection
  depends_on = [zillizcloud_byoc_i_project_agent.this,
    module.eks, module.private_link, module.vpc, module.s3]
  lifecycle {
     ignore_changes = [data_plane_id, project_id, aws, ext_config]
     prevent_destroy = true
  }

  ext_config = base64encode(jsonencode(local.ext_config))
}

output "data_plane_id" {
  value = local.dataplane_id
}

output "project_id" {
  value = local.project_id
}

output "destroy_info" {
  value = <<EOT
To destroy this infrastructure, run the following command:

ZILLIZCLOUD_API_KEY=<api_key> terraform destroy \
  -var="dataplane_id=${local.dataplane_id}" \
  -var="project_id=${local.project_id}"

Note: Replace <api_key> with your actual Zilliz Cloud API key.
EOT
}