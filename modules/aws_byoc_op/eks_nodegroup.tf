# aws_eks_addon.coredns:
resource "aws_eks_addon" "coredns" {
  addon_name    = "coredns"
  cluster_name  = aws_eks_cluster.zilliz_byoc_cluster.name
  tags = {
    "Vendor" = "zilliz-byoc"
  }
  tags_all = {
    "Vendor" = "zilliz-byoc"
  }

  depends_on = [aws_eks_node_group.core]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name    = aws_eks_cluster.zilliz_byoc_cluster.name
  addon_name      = "aws-ebs-csi-driver"

  tags = {
    "Vendor" = "zilliz-byoc"
  }
  tags_all = {
    "Vendor" = "zilliz-byoc"
  }
  
  # addon_version   = "v1.17.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.eks_addon_role.arn
  depends_on = [aws_eks_node_group.core, aws_eks_addon.coredns]
}

# aws_launch_template.default:
resource "aws_launch_template" "core" {
  description             = "Core launch template for zilliz-byoc-pulsar EKS managed node group"
  disable_api_stop        = false
  disable_api_termination = false
  name_prefix             = "zilliz-byoc-core-"
  tags = {
    "Vendor" = "zilliz-byoc"
  }
  tags_all = {
    "Vendor" = "zilliz-byoc"
  }
  vpc_security_group_ids = [
    aws_security_group.zilliz_byoc_sg.id
  ]
  
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
    tags = {
      "Name" = "zilliz-byoc-core"
      "Vendor" = "zilliz-byoc"
    }
  }
  tag_specifications {
    resource_type = "network-interface"
    tags = {
      "Name" = "zilliz-byoc-core"
      "Vendor" = "zilliz-byoc"
    }
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
      "Name" = "zilliz-byoc-core"
      "Vendor" = "zilliz-byoc"
    }
  }
}


# aws_launch_template.default:
resource "aws_launch_template" "default" {
  description             = "Custom launch template for zilliz-byoc-pulsar EKS managed node group"
  disable_api_stop        = false
  disable_api_termination = false
  name_prefix             = "zilliz-byoc-"
  tags = {
    "Vendor" = "zilliz-byoc"
  }
  tags_all = {
    "Vendor" = "zilliz-byoc"
  }
  vpc_security_group_ids = [
    aws_security_group.zilliz_byoc_sg.id
  ]

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
    tags = {
      "Name" = "zilliz-byoc-default"
      "Vendor" = "zilliz-byoc"
    }
  }
  tag_specifications {
    resource_type = "network-interface"
    tags = {
      "Name" = "zilliz-byoc-default"
      "Vendor" = "zilliz-byoc"
    }
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
      "Name" = "zilliz-byoc-default"
      "Vendor" = "zilliz-byoc"
    }
  }
}

# aws_launch_template.diskann:
resource "aws_launch_template" "diskann" {
  disable_api_stop        = false
  disable_api_termination = false
  name_prefix             = "zilliz-byoc-diskann-"

  tags = {
    "Vendor" = "zilliz-byoc"
  }
  tags_all = {
    "Vendor" = "zilliz-byoc"
  }
  user_data = "TUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UeXBlOiBtdWx0aXBhcnQvbWl4ZWQ7IGJvdW5kYXJ5PSI9PU1ZQk9VTkRBUlk9PSIKCi0tPT1NWUJPVU5EQVJZPT0KQ29udGVudC1UeXBlOiB0ZXh0L3gtc2hlbGxzY3JpcHQ7IGNoYXJzZXQ9InVzLWFzY2lpIgoKIyEvYmluL2Jhc2gKZWNobyAiUnVubmluZyBjdXN0b20gdXNlciBkYXRhIHNjcmlwdCIKaWYgKCBsc2JsayB8IGZncmVwIC1xIG52bWUxbjEgKTsgdGhlbgogICAgbWtkaXIgLXAgL21udC9kYXRhIC92YXIvbGliL2t1YmVsZXQgL3Zhci9saWIvZG9ja2VyCiAgICBta2ZzLnhmcyAvZGV2L252bWUxbjEKICAgIG1vdW50IC9kZXYvbnZtZTFuMSAvbW50L2RhdGEKICAgIGNobW9kIDA3NTUgL21udC9kYXRhCiAgICBtdiAvdmFyL2xpYi9rdWJlbGV0IC9tbnQvZGF0YS8KICAgIG12IC92YXIvbGliL2RvY2tlciAvbW50L2RhdGEvCiAgICBsbiAtc2YgL21udC9kYXRhL2t1YmVsZXQgL3Zhci9saWIva3ViZWxldAogICAgbG4gLXNmIC9tbnQvZGF0YS9kb2NrZXIgL3Zhci9saWIvZG9ja2VyCiAgICBVVUlEPSQobHNibGsgLWYgfCBncmVwIG52bWUxbjEgfCBhd2sgJ3twcmludCAkM30nKQogICAgZWNobyAiVVVJRD0kVVVJRCAgICAgL21udC9kYXRhICAgeGZzICAgIGRlZmF1bHRzLG5vYXRpbWUgIDEgICAxIiA+PiAvZXRjL2ZzdGFiCmZpCgotLT09TVlCT1VOREFSWT09LS0="
  vpc_security_group_ids = [
    aws_security_group.zilliz_byoc_sg.id
  ]

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
    tags = {
      "Name" = "zilliz-byoc-milvus"
      "Vendor" = "zilliz-byoc"
    }
  }
  tag_specifications {
    resource_type = "network-interface"
    tags = {
      "Name" = "zilliz-byoc-milvus"
      "Vendor" = "zilliz-byoc"
    }
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
      "Name" = "zilliz-byoc-milvus"
      "Vendor" = "zilliz-byoc"
    }
  }
}

# aws_eks_node_group.milvus:
resource "aws_eks_node_group" "search" {
  ami_type      = "AL2_x86_64"
  capacity_type = local.k8s_node_groups.search.capacity_type
  cluster_name  = aws_eks_cluster.zilliz_byoc_cluster.name

  instance_types = [
   local.k8s_node_groups.search.instance_types,
  ]
  labels = {
    "zilliz-group-name" = "search"
    "node-role/diskANN"    = "true"
    "node-role/milvus"     = "true"
    "node-role/nvme-quota" = "200"
  }
  node_group_name_prefix = "zilliz-byoc-search-"
  node_role_arn          = aws_iam_role.eks_role.arn
  subnet_ids = local.subnet_ids
  tags = {
    "Vendor" = "zilliz-byoc"
  }
  tags_all = {
    "Vendor" = "zilliz-byoc"
  }

  launch_template {
    id      = aws_launch_template.diskann.id
    version = aws_launch_template.diskann.latest_version
  }

  scaling_config {
    desired_size = local.k8s_node_groups.search.desired_size
    max_size     = local.k8s_node_groups.search.max_size
    min_size     = local.k8s_node_groups.search.min_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# aws_eks_node_group.core:
resource "aws_eks_node_group" "core" {
  ami_type      = "AL2_x86_64"
  capacity_type = local.k8s_node_groups.core.capacity_type
  cluster_name  = aws_eks_cluster.zilliz_byoc_cluster.name

  instance_types = [
    local.k8s_node_groups.core.instance_types,
  ]
  labels = {
    "zilliz-group-name" = "core"
    "node-role/etcd" = "true"
    "node-role/pulsar" = "true"
    "node-role/infra"       = "true",
    "node-role/vdc"         = "true",
    "node-role/milvus-tool" = "true",
    "capacity-type"         = "ON_DEMAND"
  }
  node_group_name_prefix = "zilliz-byoc-core-"
  node_role_arn          = aws_iam_role.eks_role.arn
  subnet_ids = local.subnet_ids
  tags = {
    "Vendor" = "zilliz-byoc"
  }
  tags_all = {
    "Vendor" = "zilliz-byoc"
  }
  # version = "1.27"

  launch_template {
    id      = aws_launch_template.core.id
    version = aws_launch_template.core.latest_version
  }

  scaling_config {
    desired_size = local.k8s_node_groups.core.desired_size
    max_size     = local.k8s_node_groups.core.max_size
    min_size     = local.k8s_node_groups.core.min_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [ aws_eks_addon.vpc-cni ]
}

# aws_eks_node_group.index:
resource "aws_eks_node_group" "index" {
  ami_type      = "AL2_x86_64"
  capacity_type = local.k8s_node_groups.index.capacity_type
  cluster_name  = aws_eks_cluster.zilliz_byoc_cluster.name

  instance_types = [
    local.k8s_node_groups.index.instance_types,
  ]
  labels = {
    "zilliz-group-name" = "index"
    "node-role/index-pool" = "true"
  }
  node_group_name_prefix = "zilliz-byoc-index-"
  node_role_arn          = aws_iam_role.eks_role.arn
  subnet_ids = local.subnet_ids
  tags = {
    "Vendor" = "zilliz-byoc"
  }
  tags_all = {

    "Vendor" = "zilliz-byoc"
  }
  # version = "1.27"

  launch_template {
    id      = aws_launch_template.default.id
    version = aws_launch_template.default.latest_version
  }

  scaling_config {
    desired_size = local.k8s_node_groups.index.desired_size
    max_size     = local.k8s_node_groups.index.max_size
    min_size     = local.k8s_node_groups.index.min_size
  }

  update_config {
    max_unavailable_percentage = 33
  }
  
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

}

# aws_eks_node_group.fundamental
resource "aws_eks_node_group" "fundamental" {
    ami_type      = "AL2_x86_64"
    capacity_type = local.k8s_node_groups.fundamental.capacity_type
    cluster_name  = aws_eks_cluster.zilliz_byoc_cluster.name

    instance_types = [
        local.k8s_node_groups.fundamental.instance_types,
    ]
    labels = {
        "zilliz-group-name" = "fundamental"
        "node-role/default"    = "true"
        "node-role/milvus"     = "true"
    }
    node_group_name_prefix = "zilliz-byoc-fundamental-"
    node_role_arn          = aws_iam_role.eks_role.arn
    subnet_ids = local.subnet_ids
    tags = {
        "Vendor" = "zilliz-byoc"
    }
    tags_all = {
        "Vendor" = "zilliz-byoc"
    }
    # version = "1.27"

    launch_template {
        id      = aws_launch_template.default.id
        version = aws_launch_template.default.latest_version
    }

    scaling_config {
        desired_size = local.k8s_node_groups.fundamental.desired_size
        max_size     = local.k8s_node_groups.fundamental.max_size
        min_size     = local.k8s_node_groups.fundamental.min_size
    }

    update_config {
        max_unavailable_percentage = 33
    }

    lifecycle {
      ignore_changes = [scaling_config[0].desired_size]
    }

}
