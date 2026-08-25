output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "security_group_id" {
  value = aws_security_group.zilliz_byoc_security_group.id
}

output "route_table_id" {
  value = module.vpc.private_route_table_ids
}


output "public_subnets" {
  value = module.vpc.public_subnets
}

output "availability_zones" {
  description = "Availability zones used by the private subnets"
  value       = local.azs
}
