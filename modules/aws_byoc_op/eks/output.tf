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
  value = aws_iam_role.eks_role
}

output "maintaince_role" {
  value = aws_iam_role.maintaince_role
}

output "eks_addon_role" {
  value = aws_iam_role.eks_addon_role
}

output "storage_role" {
  value = aws_iam_role.storage_role
}
