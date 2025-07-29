resource "random_id" "short_uuid" {
  byte_length = 3  # 3 bytes = 6 characters when base64 encoded
}
locals {
  is_existing_vpc = var.customer_vpc_id != ""
  short_project_id = substr(data.zillizcloud_byoc_i_project_settings.this.id, 0, 10)
  prefix_name = "zilliz-${local.short_project_id}-${random_id.short_uuid.hex}"
  dataplane_id = data.zillizcloud_byoc_i_project_settings.this.data_plane_id
  vpc_id = local.is_existing_vpc ? var.customer_vpc_id :module.vpc[0].vpc_id
  security_group_id = local.is_existing_vpc ? var.customer_security_group_id : module.vpc[0].security_group_id
  subnet_ids =  local.is_existing_vpc ? var.customer_private_subnet_ids : module.vpc[0].private_subnets
  customer_pod_subnet_ids = local.is_existing_vpc ? var.customer_pod_subnet_ids : []
  eks_control_plane_subnet_ids = local.is_existing_vpc ? var.customer_eks_control_plane_private_subnet_ids : module.vpc[0].private_subnets
  region = replace(data.zillizcloud_byoc_i_project_settings.this.region, "aws-", "")
  enable_private_link =  data.zillizcloud_byoc_i_project_settings.this.private_link_enabled
  external_id = data.zillizcloud_external_id.current.id
  agent_config = {
    auth_token = data.zillizcloud_byoc_i_project_settings.this.op_config.token
    tag        = data.zillizcloud_byoc_i_project_settings.this.op_config.agent_image_url
  }

  k8s_node_groups = data.zillizcloud_byoc_i_project_settings.this.node_quotas
  project_id = data.zillizcloud_byoc_i_project_settings.this.project_id
  data_plane_id = data.zillizcloud_byoc_i_project_settings.this.data_plane_id
  s3_bucket_id = module.s3.s3_bucket_id
  eks_role = module.eks.eks_role
  maintenance_role = module.eks.maintenance_role
  eks_addon_role = module.eks.eks_addon_role
  storage_role = module.eks.storage_role
  byoc_endpoint = local.enable_private_link ? module.private_link[0].endpoint_id : null
  enable_endpoint = var.enable_endpoint

  ext_config = {
    eks_cluster_name = module.eks.eks_cluster_name
    ecr = var.customer_ecr
  }
}