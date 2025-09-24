# Data source to fetch security group details for validation
data "aws_security_group" "node_sg" {
  # Use stable, plan-time-known keys (indexes as strings)
  for_each = { for idx, _ in var.node_security_group_ids : tostring(idx) => true }
  id       = var.node_security_group_ids[tonumber(each.key)]
}

# Local value to validate security group tags
locals {
  # Build the list of SG IDs that fail the tag check
  node_invalid_security_groups = [
    for idx, sg in data.aws_security_group.node_sg :
    var.node_security_group_ids[tonumber(idx)]
    if try(sg.tags["Vendor"], "") != "zilliz-byoc"
  ]
}

resource "null_resource" "validate_node_security_group_tags" {
  lifecycle {
    precondition {
      condition     = length(local.node_invalid_security_groups) == 0
      error_message = "These node security groups are missing Vendor=zilliz-byoc: ${join(", ", local.node_invalid_security_groups)}"
    }
  }
}