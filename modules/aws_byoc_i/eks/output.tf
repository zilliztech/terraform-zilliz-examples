output "eks_cluster_name" {
  value = aws_eks_cluster.zilliz_byoc_cluster.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.zilliz_byoc_cluster.endpoint
}

output "eks_cluster_oidc_url" {
  value = replace(aws_eks_cluster.zilliz_byoc_cluster.identity[0].oidc[0].issuer, "https://", "")
}

output "eks_cluster_oidc_issuer" {
  value = aws_eks_cluster.zilliz_byoc_cluster.identity[0].oidc[0].issuer
}
output "endpoint" {
  value = aws_eks_cluster.zilliz_byoc_cluster.endpoint
}

//aws_iam_role.eks_role.arn
output "eks_role" {
  value = var.minimal_roles.enabled ? null : aws_iam_role.eks_role[0]
}

output "maintenance_role" {
  value = aws_iam_role.maintenance_role
}

output "eks_addon_role" {
  value = aws_iam_role.eks_addon_role
}

output "storage_role" {
  value = aws_iam_role.storage_role
}

# Minimal roles outputs
output "eks_cluster_role" {
  description = "EKS cluster role (created role or external role when minimal_roles.enabled is true)"
  value = local.eks_cluster_role
}

output "eks_node_role" {
  description = "EKS node role (created role or external role when minimal_roles.enabled is true)"
  value = local.eks_node_role
}
