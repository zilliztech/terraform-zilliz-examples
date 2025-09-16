data "aws_security_group" "node_security_group" {
  id = var.security_group_ids[0]
} 
resource "aws_vpc_endpoint" "byoc_endpoint" {
  vpc_id              = var.vpc_id
  // get the vpce service id from the vpce_config
  service_name        = "com.amazonaws.vpce.${var.region}.${local.config.vpce_service_ids[var.region]}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = true

  tags = merge({
    Name   = "${var.dataplane_id}-endpoint"
    Vendor = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }, var.custom_tags)
  lifecycle {
    precondition {
      condition     = try(data.aws_security_group.node_security_group.tags["Vendor"], "") == "zilliz-byoc"
      error_message = "tag Vendor=zilliz-byoc is required for the security group"
    }
  }
}