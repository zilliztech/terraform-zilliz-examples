data "aws_subnet" "selected" {
  for_each = { for idx, subnet_id in var.subnet_ids : idx => subnet_id }
  id       = each.value
}

locals {
  non_compliant_subnets = [
    for s in data.aws_subnet.selected :
    s.id if try(s.tags["Vendor"], "") != "zilliz-byoc"
  ]
}

# validate the subnets are tagged with Vendor=zilliz-byoc
resource "null_resource" "validate_subnet_tags" {
  lifecycle {
    precondition {
      condition     = length(local.non_compliant_subnets) == 0
      error_message = "These subnets are missing Vendor=zilliz-byoc: ${join(", ", local.non_compliant_subnets)}"
    }
  }
}