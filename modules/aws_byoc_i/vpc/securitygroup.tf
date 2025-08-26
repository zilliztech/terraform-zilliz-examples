resource "aws_security_group" "zilliz_byoc_security_group" {
  name        = "${local.prefix_name}-sg"
  vpc_id      = module.vpc.vpc_id
  description = "Default security group of the VPC"

  tags = merge({
    Name = "${local.prefix_name}-sg"
    Vendor = "zilliz-byoc"
  }, var.custom_tags)
}

# Ingress rules - self-referencing for protocols
resource "aws_vpc_security_group_ingress_rule" "self_ingress" {
  for_each          = toset(local.sg_ingress_protocol)
  security_group_id = aws_security_group.zilliz_byoc_security_group.id
  
  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = each.value
  referenced_security_group_id = aws_security_group.zilliz_byoc_security_group.id
  
  tags = {
    Name = "${local.prefix_name}-sg-ingress-self-${each.value}"
  }
}

# Ingress rules - VPC CIDR for protocols
resource "aws_vpc_security_group_ingress_rule" "vpc_ingress" {
  for_each          = toset(local.sg_ingress_protocol)
  security_group_id = aws_security_group.zilliz_byoc_security_group.id
  
  from_port   = 0
  to_port     = 65535
  ip_protocol = each.value
  cidr_ipv4   = local.vpc_cidr
  
  tags = {
    Name = "${local.prefix_name}-sg-ingress-vpc-${each.value}"
  }
}

# Egress rules - self-referencing for protocols
resource "aws_vpc_security_group_egress_rule" "self_egress" {
  for_each          = toset(local.sg_egress_protocol)
  security_group_id = aws_security_group.zilliz_byoc_security_group.id
  
  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = each.value
  referenced_security_group_id = aws_security_group.zilliz_byoc_security_group.id
  
  tags = {
    Name = "${local.prefix_name}-sg-egress-self-${each.value}"
  }
}

# Egress rules - VPC CIDR for protocols
resource "aws_vpc_security_group_egress_rule" "vpc_egress" {
  for_each          = toset(local.sg_egress_protocol)
  security_group_id = aws_security_group.zilliz_byoc_security_group.id
  
  from_port   = 0
  to_port     = 65535
  ip_protocol = each.value
  cidr_ipv4   = local.vpc_cidr
  
  tags = {
    Name = "${local.prefix_name}-sg-egress-vpc-${each.value}"
  }
}

# Egress rules - external access for specific ports
resource "aws_vpc_security_group_egress_rule" "external_egress" {
  for_each          = toset([for port in local.sg_egress_ports : tostring(port)])
  security_group_id = aws_security_group.zilliz_byoc_security_group.id
  
  from_port   = tonumber(each.value)
  to_port     = tonumber(each.value)
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
  
  tags = {
    Name = "${local.prefix_name}-sg-egress-external-${each.value}"
  }
}