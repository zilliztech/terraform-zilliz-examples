# Data source to fetch security group details for validation
data "aws_security_group" "node_sg" {
  for_each = toset(var.security_group_ids)
  id       = each.value
}

# Local value to validate security group tags
locals {
  # Check if all security groups have the required Vendor tag
  invalid_security_groups = [
    for sg_id in var.security_group_ids:
    sg_id if lookup(data.aws_security_group.node_sg[sg_id].tags, "Vendor", "") != "zilliz-byoc"
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