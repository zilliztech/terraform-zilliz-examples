
module "my_vpc" {
  source = "./vpc"
  dataplane_id = var.dataplane_id
  vpc_cidr = var.vpc_cidr
  custom_tags = var.custom_tags
}

module "my_s3" {
  source = "./s3"
  region = var.aws_region
  dataplane_id = var.dataplane_id
  custom_tags = var.custom_tags
}

module "my_private_link" {
  source = "./privatelink"
  dataplane_id = var.dataplane_id
  region = var.aws_region
  enable_private_link = var.enable_private_link
  vpc_id = module.my_vpc.vpc_id
  subnet_ids = module.my_vpc.private_subnets
  security_group_ids = [module.my_vpc.security_group_id]
  custom_tags = var.custom_tags
}

module "my_eks" {
  source = "./eks"
  dataplane_id = var.dataplane_id
  region = var.aws_region
  security_group_id = module.my_vpc.security_group_id
  vpc_id = module.my_vpc.vpc_id
  subnet_ids = module.my_vpc.private_subnets
  external_id = var.external_id
  agent_config = var.agent_config
  enable_private_link = var.enable_private_link
  k8s_node_groups = var.k8s_node_groups
  s3_bucket_id = module.my_s3.s3_bucket_id
  custom_tags = var.custom_tags
}
