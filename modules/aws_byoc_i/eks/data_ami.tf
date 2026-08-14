data "aws_ami" "node_group" {
  for_each = {
    for name, node_group in var.k8s_node_groups : name => node_group
    if node_group.ami_id != null
  }

  filter {
    name   = "image-id"
    values = [each.value.ami_id]
  }
}
