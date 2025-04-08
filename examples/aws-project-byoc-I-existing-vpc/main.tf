
resource "zillizcloud_byoc_op_project_settings" "this" {
  cloud_provider = "aws"
  region         = "aws-${local.aws_region}"
  project_name   = var.name

  # required
  instances = {
    core_vm        = var.core_instance_type
    fundamental_vm = var.fundamental_instance_type
    search_vm      = var.search_instance_type
  }

}

data "zillizcloud_external_id" "current" {}


module "my_s3" {
  source = "../../modules/aws_byoc_op/s3"
  region = local.aws_region
  dataplane_id = local.dataplane_id
  vpc_id = local.vpc_id
  route_table_ids = null # TODO: module.my_vpc.route_table_id
}

module "my_private_link" {
  source = "../../modules/aws_byoc_op/privatelink"
  dataplane_id = local.dataplane_id
  region = local.aws_region
  enable_private_link = local.enable_private_link
  vpc_id = local.vpc_id
  subnet_ids = local.subnet_ids
  security_group_ids = [local.security_group_id]
}

module "my_eks" {
  source = "../../modules/aws_byoc_op/eks"
  dataplane_id = local.dataplane_id
  region = local.aws_region
  security_group_id = local.security_group_id
  vpc_id = local.vpc_id
  # route_table_ids = module.my_vpc.route_table_id
  route_table_ids = null # TODO: module.my_vpc.route_table_id
  subnet_ids = local.subnet_ids
  external_id = local.external_id
  agent_config = local.agent_config
  enable_private_link = local.enable_private_link
  k8s_node_groups = local.k8s_node_groups
  s3_bucket_id = local.s3_bucket_id
}



resource "zillizcloud_byoc_op_project_agent" "this" {
  project_id    = local.project_id
  data_plane_id = local.data_plane_id

  depends_on = [zillizcloud_byoc_op_project_settings.this, module.my_eks]
}




resource "zillizcloud_byoc_op_project" "this" {

  project_id = local.project_id
  data_plane_id = local.data_plane_id

  aws = {
    region = zillizcloud_byoc_op_project_settings.this.region

    network = {
      vpc_id             = local.vpc_id
      subnet_ids         = local.subnet_ids
      security_group_ids = [local.security_group_id]
      vpc_endpoint_id    = local.byoc_endpoint
    }
    role_arn = {
      storage       = local.storage_role.arn
      eks           = local.eks_addon_role.arn
      cross_account = local.maintaince_role.arn
    }
    storage = {
      bucket_id = local.s3_bucket_id
    }


  }

  depends_on = [zillizcloud_byoc_op_project_settings.this, zillizcloud_byoc_op_project_agent.this, module.my_eks]
  lifecycle {
    ignore_changes = [data_plane_id, project_id, aws, ext_config]

  }
}
  