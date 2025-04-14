locals {
  dataplane_id = zillizcloud_byoc_op_project_settings.this.data_plane_id
  vpc_id = var.customer_vpc_id
  security_group_id = var.customer_security_group_id
  subnet_ids = var.customer_private_subnet_ids
  eks_control_plane_subnet_ids = var.customer_eks_control_plane_private_subnet_ids
  aws_region = var.aws_region
  enable_private_link = var.enable_private_link
  external_id = data.zillizcloud_external_id.current.id
  agent_config = {
    auth_token = zillizcloud_byoc_op_project_settings.this.op_config.token
    tag        = zillizcloud_byoc_op_project_settings.this.op_config.agent_image_url
  }

  k8s_node_groups = zillizcloud_byoc_op_project_settings.this.node_quotas
  project_id = zillizcloud_byoc_op_project_settings.this.project_id
  data_plane_id = zillizcloud_byoc_op_project_settings.this.data_plane_id
  s3_bucket_id = module.my_s3.s3_bucket_id
  eks_role = module.my_eks.eks_role
  maintenance_role = module.my_eks.maintenance_role
  eks_addon_role = module.my_eks.eks_addon_role
  storage_role = module.my_eks.storage_role
  byoc_endpoint = var.enable_private_link ? module.my_private_link[0].endpoint_id : null

  ext_config = {
    eks_cluster_name = var.customer_eks_cluster_name
    ecr = var.customer_ecr
  }
}