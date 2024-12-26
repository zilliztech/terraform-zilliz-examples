output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnet_ids" {
  value = module.vpc.private_subnets
}

output "sg_id" {
  value = aws_security_group.zilliz_byoc_sg.id
}