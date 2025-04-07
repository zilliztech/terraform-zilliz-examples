resource "zillizcloud_byoc_op_project_settings" "this" {
  cloud_provider = "aws"
  region         = "aws-${var.aws_region}"
  project_name   = var.name

  # required
  instances = {
    core_vm        = var.core_instance_type
    fundamental_vm = var.fundamental_instance_type
    search_vm      = var.search_instance_type
  }

}

data "zillizcloud_external_id" "current" {}

module "aws_byoc_op" {
  source     = "../../modules/aws_byoc_op"
  aws_region = trimprefix(zillizcloud_byoc_op_project_settings.this.region, "aws-")

  vpc_cidr            = var.vpc_cidr
  enable_private_link = var.enable_private_link
  
  dataplane_id    = zillizcloud_byoc_op_project_settings.this.data_plane_id
  k8s_node_groups = zillizcloud_byoc_op_project_settings.this.node_quotas
  agent_config = {
    auth_token = zillizcloud_byoc_op_project_settings.this.op_config.token
    tag        = zillizcloud_byoc_op_project_settings.this.op_config.agent_image_url
  }

  external_id = data.zillizcloud_external_id.current.id
}

resource "zillizcloud_byoc_op_project_agent" "this" {
  project_id    = zillizcloud_byoc_op_project_settings.this.project_id
  data_plane_id = zillizcloud_byoc_op_project_settings.this.data_plane_id

  depends_on = [zillizcloud_byoc_op_project_settings.this, module.aws_byoc_op]
}




resource "zillizcloud_byoc_op_project" "this" {

  project_id = zillizcloud_byoc_op_project_settings.this.project_id
  data_plane_id = zillizcloud_byoc_op_project_settings.this.data_plane_id

  aws = {
    region = zillizcloud_byoc_op_project_settings.this.region

    network = {
      vpc_id             = module.aws_byoc_op.vpc_id
      subnet_ids         = module.aws_byoc_op.private_subnet_ids
      security_group_ids = [module.aws_byoc_op.security_group_id]
      vpc_endpoint_id    = var.enable_private_link ? module.aws_byoc_op.byoc_endpoint : null
    }
    role_arn = {
      storage       = module.aws_byoc_op.storage_role_arn
      eks           = module.aws_byoc_op.eks_addon_role_arn
      cross_account = module.aws_byoc_op.maintaince_role_arn
    }
    storage = {
      bucket_id = module.aws_byoc_op.s3_bucket_ids
    }


  }

  depends_on = [zillizcloud_byoc_op_project_settings.this, zillizcloud_byoc_op_project_agent.this, module.aws_byoc_op]
  lifecycle {
    ignore_changes = [data_plane_id, project_id, aws, ext_config]

  }
}
 