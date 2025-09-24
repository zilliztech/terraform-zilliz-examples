# Data source to fetch security group details for validation
data "aws_security_group" "input_sg" {
  # Use indexes (0..n-1) as stable keys. Length is known; element values may not be.
  for_each = { for idx, _ in var.security_group_ids : tostring(idx) => true }
  id       = var.security_group_ids[tonumber(each.key)]
}

locals {
  # Build the list of SG IDs that fail the tag check
  invalid_security_groups = [
    for idx, sg in data.aws_security_group.input_sg :
    var.security_group_ids[tonumber(idx)]
    if try(sg.tags["Vendor"], "") != "zilliz-byoc"
  ]
}

resource "null_resource" "validate_private_link_security_group_tags" {
  lifecycle {
    precondition {
      condition     = length(local.invalid_security_groups) == 0
      error_message = "These private link security groups are missing Vendor=zilliz-byoc: ${join(", ", local.invalid_security_groups)}"
    }
  }
}