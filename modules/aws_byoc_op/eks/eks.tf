data "aws_caller_identity" "current" {}

# aws_eks_cluster.my_cluster:
resource "aws_eks_cluster" "zilliz_byoc_cluster" {
  bootstrap_self_managed_addons = false
  enabled_cluster_log_types = []
  name = local.eks_cluster_name

  role_arn = local.eks_role.arn
  tags = merge({
    "Vendor" = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }, var.custom_tags)
  tags_all = merge({
    "Vendor" = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }, var.custom_tags)
  # version = "1.31"

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # kubernetes_network_config {
  #   ip_family         = "ipv4"
  #   service_ipv4_cidr = "10.255.0.0/16"
  # }

  upgrade_policy {
    support_type = "EXTENDED"
  }

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = var.eks_enable_public_access
    security_group_ids = [
      local.security_group_id
      
    ]
    subnet_ids = local.subnet_ids
  }
}



# aws_eks_addon.kube-proxy:
resource "aws_eks_addon" "kube-proxy" {
  addon_name    = "kube-proxy"
  # addon_version = "v1.27.6-eksbuild.2"
  cluster_name  = local.eks_cluster_name

  depends_on = [ aws_eks_cluster.zilliz_byoc_cluster ]
  
  tags = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  tags_all = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
}

# aws_eks_addon.vpc-cni:
resource "aws_eks_addon" "vpc-cni" {
  addon_name    = "vpc-cni"
  # addon_version = "v1.15.3-eksbuild.1"
  cluster_name  = local.eks_cluster_name
  
  depends_on = [ aws_eks_cluster.zilliz_byoc_cluster ]

  tags = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  tags_all = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
}

data "aws_eks_cluster_auth" "example" {
  name = local.eks_cluster_name
}


data "tls_certificate" "eks" {
  url = local.eks_cluster_oidc_issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = local.eks_cluster_oidc_issuer

  tags = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
}

resource "aws_eks_access_policy_association" "example" {
  cluster_name  = local.eks_cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = local.maintenance_role.arn

  access_scope {
    type       = "cluster"
  }

}

resource "aws_eks_access_entry" "test" {
  cluster_name = local.eks_cluster_name
  principal_arn     = local.maintenance_role.arn
  type  = "STANDARD"

  tags = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
}