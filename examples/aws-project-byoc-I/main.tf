data "zillizcloud_byoc_i_project_settings" "this" {
  project_id    = var.project_id
  data_plane_id = var.dataplane_id
}
data "zillizcloud_external_id" "current" {}

module "my_vpc" {
  count = local.is_existing_vpc ? 0 : 1
  source = "../../modules/aws_byoc_i/vpc"
  prefix_name = local.prefix_name
  dataplane_id = local.dataplane_id
  vpc_cidr = var.vpc_cidr
  custom_tags = var.custom_tags
  region = local.region
}

module "my_s3" {
  source = "../../modules/aws_byoc_i/s3"
  prefix_name = local.prefix_name
  dataplane_id = local.dataplane_id
  customer_bucket_name = var.customer_bucket_name
  custom_tags = var.custom_tags
}

module "my_private_link" {
  count = local.enable_private_link? 1: 0
  source = "../../modules/aws_byoc_i/privatelink"
  prefix_name = local.prefix_name
  dataplane_id = local.dataplane_id
  region = local.region
  enable_private_link = local.enable_private_link
  vpc_id = local.vpc_id
  subnet_ids = local.subnet_ids
  security_group_ids = [local.security_group_id]
  custom_tags = var.custom_tags
}

module "my_eks" {
  source = "../../modules/aws_byoc_i/eks"
  prefix_name = local.prefix_name
  dataplane_id = local.dataplane_id
  region = local.region
  security_group_id = local.security_group_id
  vpc_id = local.vpc_id
  subnet_ids = local.subnet_ids
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
}



resource "zillizcloud_byoc_i_project_agent" "this" {
  project_id    = local.project_id
  data_plane_id = local.data_plane_id

  depends_on = [module.my_eks]
}




resource "zillizcloud_byoc_i_project" "this" {

  project_id    = local.project_id
  data_plane_id = local.data_plane_id

  aws = {
    region = data.zillizcloud_byoc_i_project_settings.this.region

    network = {
      vpc_id             = local.vpc_id
      subnet_ids         = local.subnet_ids
      security_group_ids = [local.security_group_id]
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
    module.my_eks, module.my_private_link, module.my_vpc]
  lifecycle {
     ignore_changes = [data_plane_id, project_id, aws, ext_config]
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