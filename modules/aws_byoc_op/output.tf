output "eks_oidc_url" {
  value = local.eks_oidc_url
}

output "s3_bucket_ids" {
  value = local.bucket_id
}

# IAM Roles
output "storage_role_arn" {
  description = "ARN of the storage role for S3 access"
  value       = aws_iam_role.storage_role.arn
}

output "eks_addon_role_arn" {
  description = "ARN of the EKS addon role"
  value       = aws_iam_role.eks_addon_role.arn
}

output "eks_role_arn" {
  description = "ARN of the EKS cluster role"
  value       = aws_iam_role.eks_role.arn
}

output "maintaince_role_arn" {
  description = "ARN of the maintenance role for cluster administration"
  value       = aws_iam_role.maintaince_role.arn
}

# VPC Resources
output "vpc_id" {
  description = "ID of the VPC"
  value       = local.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = local.private_subnets
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = local.public_subnets
}

# Security Group
output "security_group_id" {
  description = "ID of the security group for the EKS cluster"
  value       = local.sg_id
}

# EKS Cluster
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.zilliz_byoc_cluster.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = aws_eks_cluster.zilliz_byoc_cluster.endpoint
}

//byoc_endpoint
output "byoc_endpoint" {
  description = "Endpoint for the BYOC"
  value       = var.enable_private_link ? aws_vpc_endpoint.byoc_endpoint[0].id : null
}
