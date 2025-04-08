data "zillizcloud_byoc_op_project_settings" "this" {
  project_id    = var.project_id
  data_plane_id = var.dataplane_id
}

data "zillizcloud_external_id" "current" {}

module "aws_byoc_op" {
  source     = "../../modules/aws_byoc_op"
  aws_region = trimprefix(data.zillizcloud_byoc_op_project_settings.this.region, "aws-")

  // network related
  vpc_cidr             = var.vpc_cidr
  enable_private_link  = var.enable_private_link
  vpc_id               = var.vpc_id
  private_subnets      = var.private_subnets
  sg_id                = var.sg_id

  // bucket related
  bucket_id          = var.bucket_id

  // eks related
  eks_cluster_name     = var.eks_cluster_name

  // role related
  eks_addon_role_name   = var.eks_addon_role_name
  eks_role_name         = var.eks_role_name
  maintenance_role_name = var.maintenance_role_name
  storage_role_name     = var.storage_role_name
  
  dataplane_id    = data.zillizcloud_byoc_op_project_settings.this.data_plane_id
  k8s_node_groups = data.zillizcloud_byoc_op_project_settings.this.node_quotas
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
  project_id = data.zillizcloud_byoc_op_project_settings.this.project_id
  data_plane_id = data.zillizcloud_byoc_op_project_settings.this.data_plane_id
  ext_config = len(var.ecr) > 0 ? var.ecr : null

  aws = {
    region = data.zillizcloud_byoc_op_project_settings.this.region

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
