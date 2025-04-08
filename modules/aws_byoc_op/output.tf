output "eks_oidc_url" {
  value = local.eks_oidc_url
}

output "s3_bucket_ids" {
  value = local.bucket_id
}

# IAM Roles
output "storage_role_arn" {
  description = "ARN of the storage role for S3 access"
  value       = local.storage_role.arn
}

output "eks_addon_role_arn" {
  description = "ARN of the EKS addon role"
  value       = local.eks_addon_role.arn
}

output "eks_role_arn" {
  description = "ARN of the EKS cluster role"
  value       = local.eks_role.arn
}

output "maintenance_role_arn" {
  description = "ARN of the maintenance role for cluster administration"
  value       = local.maintenance_role.arn
}

# VPC Resources
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.my_vpc.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.my_vpc.private_subnets
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.my_vpc.public_subnets
}

# Security Group
output "security_group_id" {
  description = "ID of the security group for the EKS cluster"
  value       = module.my_vpc.security_group_id
}

# EKS Cluster
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = local.eks_cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = module.my_eks.endpoint
}

//byoc_endpoint
output "byoc_endpoint" {
  description = "Endpoint for the BYOC"
  value       = var.enable_private_link ? module.my_private_link.endpoint_id : null
}
