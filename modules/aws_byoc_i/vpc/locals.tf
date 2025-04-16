locals {
  prefix_name = var.prefix_name
  # Dataplane ID for resource naming
  dataplane_id = var.dataplane_id

  # VPC CIDR block
  vpc_cidr = var.vpc_cidr

  # Security group ingress protocols
  sg_ingress_protocol = ["tcp", "udp"]

  # Security group egress protocols
  sg_egress_protocol = ["tcp", "udp"]

  # Security group egress ports for external access
  sg_egress_ports = [443]
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)

  // auto-generate private subnets cidr
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 2, k)]
  public_subnets  = [cidrsubnet(cidrsubnet(var.vpc_cidr, 2, 3), 6, 62)]
} 
