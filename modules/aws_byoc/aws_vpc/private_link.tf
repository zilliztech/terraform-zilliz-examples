data aws_caller_identity "current" {}

locals {
  config = yamldecode(file("${path.module}/../conf.yaml"))
}

resource "aws_vpc_endpoint" "byoc_endpoint" {
  count = var.enable_private_link ? 1 : 0

  vpc_id              = module.vpc.vpc_id
  // get the vpce service id from the vpce_config
  service_name        = "com.amazonaws.vpce.${var.region}.${local.config.vpce_service_ids[var.region]}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.zilliz_byoc_sg.id]
  private_dns_enabled = true

  tags = {
    Name   = "zilliz-byoc-${var.name}-endpoint"
    Vendor = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }
}