resource "aws_security_group" "byoc_endpoint_sg" {
  count       = var.create_security_group ? 1 : 0
  name        = var.security_group_name != "" ? var.security_group_name : "${var.dataplane_id}-endpoint-sg"
  description = "Security group for Zilliz BYOC PrivateLink endpoint"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name   = "${var.dataplane_id}-endpoint-sg"
    Vendor = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }, var.custom_tags)

  lifecycle {
    # maybe the user will update the ingress rules
    ignore_changes = [ ingress ]
  }
}
