resource "aws_security_group" "zilliz_byoc_sg" {
  name        = "${var.name}-sg"
  vpc_id      = module.vpc.vpc_id
  description = "Default security group of the VPC"

  dynamic "ingress" {
    for_each = local.sg_ingress_protocol
    content {
      from_port   = 0
      to_port     = 65535
      protocol    = ingress.value
      self = true
    }
  }

  dynamic "ingress" {
    for_each = local.sg_ingress_protocol
    content {
      from_port   = 0
      to_port     = 65535
      protocol    = ingress.value
      cidr_blocks = [var.vpc_cidr]
    }
  }

  dynamic "egress" {
    for_each = local.sg_egress_protocol
    content {
      from_port = 0
      to_port   = 65535
      protocol  = egress.value
      self      = true
    }
  }

  dynamic "egress" {
    for_each = local.sg_egress_protocol
    content {
      from_port = 0
      to_port   = 65535
      protocol  = egress.value
      cidr_blocks = [var.vpc_cidr]
    }
  }

  dynamic "egress" {
    for_each = local.sg_egress_ports
    content {
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Name = "${var.name}-sg"
    Vendor = "zilliz-byoc"
  }
  lifecycle {
      ignore_changes = [
        ingress,
      ]
  }
}
