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

module "vpc" {
  source = "../../modules/aws_byoc_op/vpc"
  dataplane_id = zillizcloud_byoc_op_project_settings.this.data_plane_id
  vpc_cidr = var.vpc_cidr
}

moved {
  from = module.aws_byoc_op.aws_security_group.zilliz_byoc_sg
  to   = module.vpc.aws_security_group.zilliz_byoc_security_group
}

moved {
  from = module.aws_byoc_op.module.vpc
  to   = module.vpc.module.vpc
}



module "private_link" {
  source = "../../modules/aws_byoc_op/privatelink"
  dataplane_id = zillizcloud_byoc_op_project_settings.this.data_plane_id
  region = var.aws_region
  enable_private_link = var.enable_private_link
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  security_group_ids = [module.vpc.security_group_id]
}

moved {
  from = module.aws_byoc_op.aws_vpc_endpoint.byoc_endpoint
  to   = module.private_link.aws_vpc_endpoint.byoc_endpoint
}


moved {
  from = module.aws_byoc_op.aws_route53_zone.byoc_private_zone
  to   = module.private_link.aws_route53_zone.byoc_private_zone
}

moved {
  from = module.aws_byoc_op.aws_route53_record.byoc_endpoint_alias
  to   = module.private_link.aws_route53_record.byoc_endpoint_alias
}


module "s3" {
  source = "../../modules/aws_byoc_op/s3"
  region = var.aws_region
  dataplane_id = zillizcloud_byoc_op_project_settings.this.data_plane_id
  vpc_id = module.vpc.vpc_id
  route_table_ids = module.vpc.route_table_id

}

moved {
  from = module.aws_byoc_op.module.s3_bucket
  to   = module.s3.module.s3_bucket
}

moved {
  from = module.aws_byoc_op.aws_vpc_endpoint.s3
  to   = module.s3.aws_vpc_endpoint.s3
}
