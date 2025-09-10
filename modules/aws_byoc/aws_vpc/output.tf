output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnet_ids" {
  value = module.vpc.private_subnets
}

output "sg_id" {
  value = aws_security_group.zilliz_byoc_sg.id
}


output "vpc_endpoint" {
  value = var.enable_private_link ? aws_vpc_endpoint.byoc_endpoint[0].id : null
}