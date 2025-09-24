data "aws_caller_identity" "current" {}

locals {
  config             = yamldecode(file("${path.module}/../../conf.yaml"))
  security_group_ids = var.create_security_group ? [aws_security_group.byoc_endpoint_sg[0].id] : var.security_group_ids
}