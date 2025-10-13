# aws_eks_addon.coredns:
resource "aws_eks_addon" "coredns" {
  addon_name   = "coredns"
  cluster_name = local.eks_cluster_name
  tags = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  tags_all = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)

  depends_on = [aws_eks_node_group.core]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name = local.eks_cluster_name
  addon_name   = "aws-ebs-csi-driver"

  tags = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  tags_all = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)

  # addon_version   = "v1.17.0-eksbuild.1"
  service_account_role_arn = local.eks_addon_role.arn
  depends_on               = [aws_eks_node_group.core, aws_eks_addon.coredns]
}



# aws_launch_template.default:
resource "aws_launch_template" "core" {
  description             = "Core launch template for zilliz-byoc-pulsar EKS managed node group"
  disable_api_stop        = false
  disable_api_termination = false
  name_prefix             = "zilliz-byoc-core-"
  tags = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  tags_all = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  vpc_security_group_ids = local.node_security_group_ids

  user_data = local.core_user_data
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge({
      "Name"   = "zilliz-byoc-core"
      "Vendor" = "zilliz-byoc"
    }, var.custom_tags)
  }
  tag_specifications {
    resource_type = "network-interface"
    tags = merge({
      "Name"   = "zilliz-byoc-core"
      "Vendor" = "zilliz-byoc"
    }, var.custom_tags)
  }
  tag_specifications {
    resource_type = "volume"
    tags = merge({
      "Name"   = "zilliz-byoc-core"
      "Vendor" = "zilliz-byoc"
    }, var.custom_tags)
  }

  depends_on = [ aws_iam_role_policy_attachment.maintenance_policy_attachment_2, aws_iam_role_policy_attachment.maintenance_policy_attachment_1 ]
}


# aws_launch_template.default:
resource "aws_launch_template" "init" {
  description             = "Init launch template for zilliz-byoc-pulsar EKS managed node group"
  disable_api_stop        = false
  disable_api_termination = false
  name_prefix             = "zilliz-byoc-init-"
  tags = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  tags_all = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  vpc_security_group_ids = local.node_security_group_ids

  user_data = local.init_user_data
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge({
      "Name"   = "zilliz-byoc-init"
      "Vendor" = "zilliz-byoc"
    }, var.custom_tags)
  }
  tag_specifications {
    resource_type = "network-interface"
    tags = merge({
      "Name"   = "zilliz-byoc-init"
      "Vendor" = "zilliz-byoc"
    }, var.custom_tags)
  }
  tag_specifications {
    resource_type = "volume"
    tags = merge({
      "Name"   = "zilliz-byoc-init"
      "Vendor" = "zilliz-byoc"
    }, var.custom_tags)
  }

  depends_on = [ aws_iam_role_policy_attachment.maintenance_policy_attachment_2, aws_iam_role_policy_attachment.maintenance_policy_attachment_1 ]


}


# aws_launch_template.default:
resource "aws_launch_template" "default" {
  description             = "Custom launch template for zilliz-byoc-pulsar EKS managed node group"
  disable_api_stop        = false
  disable_api_termination = false
  name_prefix             = "zilliz-byoc-"
  tags = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  tags_all = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  vpc_security_group_ids = local.node_security_group_ids

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge({
      "Name"   = "zilliz-byoc-default"
      "Vendor" = "zilliz-byoc"
    }, var.custom_tags)
  }
  tag_specifications {
    resource_type = "network-interface"
    tags = merge({
      "Name"   = "zilliz-byoc-default"
      "Vendor" = "zilliz-byoc"
    }, var.custom_tags)
  }
  tag_specifications {
    resource_type = "volume"
    tags = merge({
      "Name"   = "zilliz-byoc-default"
      "Vendor" = "zilliz-byoc"
    }, var.custom_tags)
  }
}

# aws_launch_template.diskann:
resource "aws_launch_template" "diskann" {
  disable_api_stop        = false
  disable_api_termination = false
  name_prefix             = "zilliz-byoc-diskann-"

  tags = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  tags_all = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  user_data = "TUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UeXBlOiBtdWx0aXBhcnQvbWl4ZWQ7IGJvdW5kYXJ5PSI9PU1ZQk9VTkRBUlk9PSIKCi0tPT1NWUJPVU5EQVJZPT0KQ29udGVudC1UeXBlOiB0ZXh0L3gtc2hlbGxzY3JpcHQ7IGNoYXJzZXQ9InVzLWFzY2lpIgoKIyEvYmluL2Jhc2gKZWNobyAiUnVubmluZyB6aWxsaXogY3VzdG9tIHVzZXIgZGF0YSBzY3JpcHQiCmRpc2tfdm9sdW1lPSQobHNibGsgLUogLW8gTkFNRSxNT0RFTCxTSVpFIHwganEgLXIgJy5ibG9ja2RldmljZXNbXSB8IHNlbGVjdCgubW9kZWwgfCB0ZXN0KCJBbWF6b24gRUMyIE5WTWUgSW5zdGFuY2UgU3RvcmFnZSIpKSB8IC5uYW1lJykKZWNobyAke2Rpc2tfdm9sdW1lfQppZiAoIGxzYmxrIHwgZmdyZXAgLXEgJHtkaXNrX3ZvbHVtZX0gKTsgdGhlbgogICAgbWtkaXIgLXAgL21udC9kYXRhIC92YXIvbGliL2t1YmVsZXQgL3Zhci9saWIvZG9ja2VyCiAgICBta2ZzLnhmcyAvZGV2LyR7ZGlza192b2x1bWV9CiAgICBtb3VudCAvZGV2LyR7ZGlza192b2x1bWV9IC9tbnQvZGF0YQogICAgY2htb2QgMDc1NSAvbW50L2RhdGEKICAgIG12IC92YXIvbGliL2t1YmVsZXQgL21udC9kYXRhLwogICAgbXYgL3Zhci9saWIvZG9ja2VyIC9tbnQvZGF0YS8KICAgIGxuIC1zZiAvbW50L2RhdGEva3ViZWxldCAvdmFyL2xpYi9rdWJlbGV0CiAgICBsbiAtc2YgL21udC9kYXRhL2RvY2tlciAvdmFyL2xpYi9kb2NrZXIKICAgIFVVSUQ9JChsc2JsayAtZiB8IGdyZXAgJHtkaXNrX3ZvbHVtZX0gfCBhd2sgJ3twcmludCAkM30nKQogICAgZWNobyAiVVVJRD0kVVVJRCAgICAgL21udC9kYXRhICAgeGZzICAgIGRlZmF1bHRzLG5vYXRpbWUgIDEgICAxIiA+PiAvZXRjL2ZzdGFiCgpmaQplY2hvICJtb3VudCByZXN1bHRzICQoY2F0IC9ldGMvZnN0YWIpIgoKZWNobyAnVXNlciBkYXRhIHNjcmlwdCBkb25lJwotLT09TVlCT1VOREFSWT09LS0K"
  vpc_security_group_ids = local.node_security_group_ids

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = "true"
      encrypted             = "false"
      iops                  = 3000
      throughput            = 125
      volume_size           = 100
      volume_type           = "gp3"
    }
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge({
      "Name"   = "zilliz-byoc-milvus"
      "Vendor" = "zilliz-byoc"
    }, var.custom_tags)
  }
  tag_specifications {
    resource_type = "network-interface"
    tags = merge({
      "Name"   = "zilliz-byoc-milvus"
      "Vendor" = "zilliz-byoc"
    }, var.custom_tags)
  }
  tag_specifications {
    resource_type = "volume"
    tags = merge({
      "Name"   = "zilliz-byoc-milvus"
      "Vendor" = "zilliz-byoc"
    }, var.custom_tags)
  }


}


# Determine AMI type based on instance architecture
locals {
  # Map instance types to their appropriate AMI types
  # ARM instances typically have 'g' in their generation identifier (e.g., m6g, c7g, t4g)
  # This regex matches instance types with 'g' after the number, which indicates ARM architecture
  ami_types = {
    search      = can(regex("^[a-z]+[0-9]+g[a-z]*\\.", var.k8s_node_groups.search.instance_types)) ? "AL2023_ARM_64_STANDARD" : "AL2023_x86_64_STANDARD"
    core        = can(regex("^[a-z]+[0-9]+g[a-z]*\\.", var.k8s_node_groups.core.instance_types)) ? "AL2023_ARM_64_STANDARD" : "AL2023_x86_64_STANDARD"
    index       = can(regex("^[a-z]+[0-9]+g[a-z]*\\.", var.k8s_node_groups.index.instance_types)) ? "AL2023_ARM_64_STANDARD" : "AL2023_x86_64_STANDARD"
    fundamental = can(regex("^[a-z]+[0-9]+g[a-z]*\\.", var.k8s_node_groups.fundamental.instance_types)) ? "AL2023_ARM_64_STANDARD" : "AL2023_x86_64_STANDARD"
  }
}

# aws_eks_node_group.milvus:
resource "aws_eks_node_group" "search" {
  ami_type      = local.ami_types.search
  capacity_type = local.k8s_node_groups.search.capacity_type
  cluster_name  = local.eks_cluster_name

  instance_types = [
    local.k8s_node_groups.search.instance_types,
  ]
  labels = {
    "zilliz-group-name"    = "search"
    "node-role/diskANN"    = "true"
    "node-role/milvus"     = "true"
    "node-role/nvme-quota" = "200"
  }
  node_group_name_prefix = "${local.prefix_name}-search-"
  node_role_arn          = local.eks_node_role_arn
  subnet_ids             = local.subnet_ids
  tags = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  tags_all = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)

  launch_template {
    id      = aws_launch_template.diskann.id
    version = aws_launch_template.diskann.latest_version
  }

  scaling_config {
    desired_size = local.k8s_node_groups.search.min_size
    max_size     = local.k8s_node_groups.search.max_size
    min_size     = local.k8s_node_groups.search.min_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]

  }

  depends_on = [aws_eks_addon.vpc-cni, time_sleep.wait_init]
}

# aws_eks_node_group.core:
resource "aws_eks_node_group" "core" {
  ami_type      = local.ami_types.core
  capacity_type = local.k8s_node_groups.core.capacity_type
  cluster_name  = local.eks_cluster_name

  instance_types = [
    local.k8s_node_groups.core.instance_types,
  ]
  labels = {
    "zilliz-group-name"     = "core"
    "node-role/etcd"        = "true"
    "node-role/pulsar"      = "true"
    "node-role/infra"       = "true",
    "node-role/vdc"         = "true",
    "node-role/milvus-tool" = "true",
    "capacity-type"         = "ON_DEMAND"
  }
  node_group_name_prefix = "${local.prefix_name}-core-"
  node_role_arn          = local.eks_node_role_arn
  subnet_ids             = local.subnet_ids
  tags = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  tags_all = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  # version = "1.27"

  launch_template {
    id      = aws_launch_template.core.id
    version = aws_launch_template.core.latest_version
  }

  scaling_config {
    desired_size = local.k8s_node_groups.core.min_size
    max_size     = local.k8s_node_groups.core.max_size
    min_size     = local.k8s_node_groups.core.min_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [aws_eks_addon.vpc-cni, time_sleep.wait_init]
}

# aws_eks_node_group.index:
resource "aws_eks_node_group" "index" {
  ami_type      = local.ami_types.index
  capacity_type = local.k8s_node_groups.index.capacity_type
  cluster_name  = local.eks_cluster_name

  instance_types = [
    local.k8s_node_groups.index.instance_types,
  ]
  labels = {
    "zilliz-group-name"    = "index"
    "node-role/index-pool" = "true"
  }
  node_group_name_prefix = "${local.prefix_name}-index-"
  node_role_arn          = local.eks_node_role_arn
  subnet_ids             = local.subnet_ids
  tags = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  tags_all = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  # version = "1.27"

  launch_template {
    id      = aws_launch_template.default.id
    version = aws_launch_template.default.latest_version
  }

  scaling_config {
    desired_size = local.k8s_node_groups.index.min_size
    max_size     = local.k8s_node_groups.index.max_size
    min_size     = local.k8s_node_groups.index.min_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]

  }

  depends_on = [aws_eks_addon.vpc-cni, time_sleep.wait_init]
}

# aws_eks_node_group.fundamental
resource "aws_eks_node_group" "fundamental" {
  ami_type      = local.ami_types.fundamental
  capacity_type = local.k8s_node_groups.fundamental.capacity_type
  cluster_name  = local.eks_cluster_name

  instance_types = [
    local.k8s_node_groups.fundamental.instance_types,
  ]
  labels = {
    "zilliz-group-name" = "fundamental"
    "node-role/default" = "true"
    "node-role/milvus"  = "true"
  }
  node_group_name_prefix = "${local.prefix_name}-fundamental-"
  node_role_arn          = local.eks_node_role_arn
  subnet_ids             = local.subnet_ids
  tags = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  tags_all = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  # version = "1.27"

  launch_template {
    id      = aws_launch_template.default.id
    version = aws_launch_template.default.latest_version
  }

  scaling_config {
    desired_size = local.k8s_node_groups.fundamental.min_size
    max_size     = local.k8s_node_groups.fundamental.max_size
    min_size     = local.k8s_node_groups.fundamental.min_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]

  }

  depends_on = [aws_eks_addon.vpc-cni, time_sleep.wait_init]
}

resource "time_sleep" "wait_init" {
  depends_on = [aws_eks_node_group.init]

  create_duration = "30s"
}

resource "aws_eks_node_group" "init" {
  ami_type      = "AL2023_x86_64_STANDARD"
  capacity_type = "ON_DEMAND"
  cluster_name  = local.eks_cluster_name

  instance_types = [
    "t3.medium",
  ]
  labels = {
    "zilliz-group-name" = "init"
    "node-role/init" = "true"
  }
  node_group_name_prefix = "${local.prefix_name}-init-"
  node_role_arn          = local.eks_node_role_arn
  subnet_ids             = local.subnet_ids
  tags = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  tags_all = merge({
    "Vendor" = "zilliz-byoc"
  }, var.custom_tags)
  # version = "1.27"

  launch_template {
    id      = aws_launch_template.init.id
    version = aws_launch_template.init.latest_version
  }

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 0
  }

  update_config {
    max_unavailable_percentage = 33
  }

  lifecycle {
    ignore_changes = [scaling_config]
  }

  depends_on = [aws_eks_addon.vpc-cni]
}
