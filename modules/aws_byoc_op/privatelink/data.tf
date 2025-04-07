data "aws_caller_identity" "current" {}

locals {
  config = yamldecode(file("${path.module}/conf.yaml"))
}