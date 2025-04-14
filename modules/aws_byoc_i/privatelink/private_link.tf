resource "aws_vpc_endpoint" "byoc_endpoint" {
  count = var.enable_private_link ? 1 : 0

  vpc_id              = var.vpc_id
  // get the vpce service id from the vpce_config
  service_name        = "com.amazonaws.vpce.${var.region}.${local.config.vpce_service_ids[var.region]}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  # private_dns_enabled = true

  tags = merge({
    Name   = "${var.dataplane_id}-endpoint"
    Vendor = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }, var.custom_tags)
}


resource "aws_route53_zone" "byoc_private_zone" {
  count = var.enable_private_link ? 1 : 0
  # if the region is us-west-2, the private zone name is zilliz-byoc-us.byoc.zillizcloud.com
  # if the region is eu-central-1, the private zone name is zilliz-byoc-eu.byoc.zillizcloud.com
  name = "zilliz-byoc-${substr(var.region, 0, 2)}.${local.config.private_zone_name}"  
  vpc {
    vpc_id = var.vpc_id
  }
  comment = "Private hosted zone for BYOC project"

  tags = merge({
    Vendor = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }, var.custom_tags)
}

resource "aws_route53_record" "byoc_endpoint_alias" {
  count = var.enable_private_link ? 1 : 0
  zone_id = aws_route53_zone.byoc_private_zone[0].zone_id
  name    = ""
  type    = "A"

  alias {
    name                   = aws_vpc_endpoint.byoc_endpoint[0].dns_entry[0].dns_name
    zone_id               = aws_vpc_endpoint.byoc_endpoint[0].dns_entry[0].hosted_zone_id
    evaluate_target_health = true
  }
}