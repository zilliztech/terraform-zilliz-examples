data aws_caller_identity "current" {}

locals {
  config = yamldecode(file("${path.module}/conf.yaml"))
}

resource "aws_vpc_endpoint" "byoc_endpoint" {
  count = var.enable_private_link ? 1 : 0

  vpc_id              = module.vpc.vpc_id
  // get the vpce service id from the vpce_config
  service_name        = "com.amazonaws.vpce.${var.aws_region}.${local.config.vpce_service_ids[var.aws_region]}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.zilliz_byoc_sg.id]
  # private_dns_enabled = true

  tags = {
    Name   = "zilliz-byoc-${var.name}-endpoint"
    Vendor = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }
}


resource "aws_route53_zone" "byoc_private_zone" {
  count = var.enable_private_link ? 1 : 0
  name = local.config.private_zone_name
  vpc {
    vpc_id = module.vpc.vpc_id
  }
  comment = "Private hosted zone for BYOC project"

  tags = {
    Vendor = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }
}

resource "aws_route53_record" "byoc_endpoint_alias" {
  count = var.enable_private_link ? 1 : 0
  zone_id = aws_route53_zone.byoc_private_zone[0].zone_id
  # if us-west-2, the name is zilliz-byoc-us
  # if eu-central-1, the name is zilliz-byoc-eu
  name    = "zilliz-byoc-${substr(var.aws_region, 0, 2)}"
  type    = "A"

  alias {
    name                   = aws_vpc_endpoint.byoc_endpoint[0].dns_entry[0].dns_name
    zone_id               = aws_vpc_endpoint.byoc_endpoint[0].dns_entry[0].hosted_zone_id
    evaluate_target_health = true
  }
}