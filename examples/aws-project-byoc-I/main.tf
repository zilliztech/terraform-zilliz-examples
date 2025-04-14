data "zillizcloud_byoc_op_project_settings" "this" {
  project_id    = var.project_id
  data_plane_id = var.dataplane_id
}

data "zillizcloud_external_id" "current" {}

module "aws_byoc_op" {
  source     = "../../modules/aws_byoc_I"
  aws_region = trimprefix(data.zillizcloud_byoc_op_project_settings.this.region, "aws-")

  vpc_cidr            = var.vpc_cidr
  enable_private_link = data.zillizcloud_byoc_op_project_settings.this.private_link_enabled
  dataplane_id        = data.zillizcloud_byoc_op_project_settings.this.data_plane_id
  k8s_node_groups     = data.zillizcloud_byoc_op_project_settings.this.node_quotas
  agent_config = {
    auth_token = data.zillizcloud_byoc_op_project_settings.this.op_config.token
    tag        = data.zillizcloud_byoc_op_project_settings.this.op_config.agent_image_url
  }

  external_id = data.zillizcloud_external_id.current.id
}

resource "zillizcloud_byoc_op_project_agent" "this" {
  project_id    = data.zillizcloud_byoc_op_project_settings.this.project_id
  data_plane_id = data.zillizcloud_byoc_op_project_settings.this.data_plane_id
}


resource "zillizcloud_byoc_op_project" "this" {

  project_id    = data.zillizcloud_byoc_op_project_settings.this.project_id
  data_plane_id = data.zillizcloud_byoc_op_project_settings.this.data_plane_id

  aws = {
    region = data.zillizcloud_byoc_op_project_settings.this.region

    network = {
      vpc_id             = module.aws_byoc_op.vpc_id
      subnet_ids         = module.aws_byoc_op.private_subnet_ids
      security_group_ids = [module.aws_byoc_op.security_group_id]
      vpc_endpoint_id    = data.zillizcloud_byoc_op_project_settings.this.private_link_enabled ? module.aws_byoc_op.byoc_endpoint : null
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

  depends_on = [data.zillizcloud_byoc_op_project_settings.this, zillizcloud_byoc_op_project_agent.this, module.aws_byoc_op]
  lifecycle {
    ignore_changes = [data_plane_id, project_id, aws, ext_config]

  }
}

output "data_plane_id" {
  value = data.zillizcloud_byoc_op_project_settings.this.data_plane_id
}

output "project_id" {
  value = data.zillizcloud_byoc_op_project_settings.this.project_id
}
