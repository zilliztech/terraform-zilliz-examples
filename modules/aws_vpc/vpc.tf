locals {
  // available zones
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 2, k)]
  public_subnets  = [cidrsubnet(cidrsubnet(var.vpc_cidr, 2, 3), 6, 62)]
  sg_egress_ports                = [443]
  sg_ingress_protocol            = ["tcp", "udp"]
  sg_egress_protocol             = ["tcp", "udp"]
}

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.15.0"

  name = "${var.name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  // e.g. if var.vpc_cidr = "10.0.0.0/16", private_subnets = ["10.0.0.0/18", "10.0.64.0/18","10.0.128.0/18"]，public_subnets = ["10.0.254.0/24"]
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  private_subnet_names = [
    "${var.name}-vpc-${local.azs[0]}",
    "${var.name}-vpc-${local.azs[1]}",
    "${var.name}-vpc-${local.azs[2]}"
  ]
  public_subnet_names = ["${var.name}-vpc-public-${local.azs[0]}"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  //all private subnets will route their Internet traffic through the single NAT gateway. The NAT gateway will be placed in the first public subnet in the public_subnets block.
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false

  //https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/alb-ingress.html
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  default_network_acl_tags = {
    Vendor    = "zilliz-byoc"
  }

  tags = {
    Vendor    = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }
}


data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.region}.s3"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.region}.s3"

  route_table_ids = module.vpc.private_route_table_ids
}