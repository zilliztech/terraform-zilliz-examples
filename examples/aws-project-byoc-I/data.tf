resource "random_id" "short_uuid" {
  byte_length = 3  # 3 bytes = 6 characters when base64 encoded
}
locals {
  is_existing_vpc = var.customer_vpc_id != ""
  short_project_id = substr(data.zillizcloud_byoc_op_project_settings.this.id, 0, 10)
  prefix_name = "zilliz-${local.short_project_id}-${random_id.short_uuid.hex}"
  dataplane_id = data.zillizcloud_byoc_op_project_settings.this.data_plane_id
  vpc_id = var.customer_vpc_id
  security_group_id = local.is_existing_vpc ? var.customer_security_group_id : module.my_vpc[0].security_group_id
  subnet_ids =  local.is_existing_vpc ? var.customer_private_subnet_ids : module.my_vpc[0].private_subnets
  eks_control_plane_subnet_ids = local.is_existing_vpc ? var.customer_eks_control_plane_private_subnet_ids : module.my_vpc[0].private_subnets
  aws_region = replace(data.zillizcloud_byoc_op_project_settings.this.region, "aws-", "")
  enable_private_link = var.enable_private_link
  external_id = data.zillizcloud_external_id.current.id
  agent_config = {
    auth_token = data.zillizcloud_byoc_op_project_settings.this.op_config.token
    tag        = data.zillizcloud_byoc_op_project_settings.this.op_config.agent_image_url
  }

  k8s_node_groups = data.zillizcloud_byoc_op_project_settings.this.node_quotas
  project_id = data.zillizcloud_byoc_op_project_settings.this.project_id
  data_plane_id = data.zillizcloud_byoc_op_project_settings.this.data_plane_id
  s3_bucket_id = module.my_s3.s3_bucket_id
  eks_role = module.my_eks.eks_role
  maintenance_role = module.my_eks.maintenance_role
  eks_addon_role = module.my_eks.eks_addon_role
  storage_role = module.my_eks.storage_role
  byoc_endpoint = var.enable_private_link ? module.my_private_link[0].endpoint_id : null

  ext_config = {
    eks_cluster_name = module.my_eks.eks_cluster_name
    ecr = var.customer_ecr
  }
}