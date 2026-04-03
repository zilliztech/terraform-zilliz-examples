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
  image_id               = local.k8s_node_groups.core.ami_id

  user_data = local.core_user_data
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = "true"
      encrypted             = var.enable_ebs_kms ? "true" : "false"
      kms_key_id            = var.enable_ebs_kms ? var.ebs_kms_key_arn : null
      volume_size           = var.k8s_node_groups.core.disk_size
      volume_type           = "gp3"
    }
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

  depends_on = [aws_iam_role_policy_attachment.maintenance_policy_attachment_2, aws_iam_role_policy_attachment.maintenance_policy_attachment_1]
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
  image_id               = local.k8s_node_groups.core.ami_id

  user_data = local.init_user_data
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }

  dynamic "block_device_mappings" {
    for_each = var.enable_ebs_kms ? [1] : []
    content {
      device_name = "/dev/xvda"
      ebs {
        encrypted    = "true"
        kms_key_id   = var.ebs_kms_key_arn
        volume_size  = var.ebs_volume_size
        volume_type  = var.ebs_volume_type
      }
    }
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

  depends_on = [aws_iam_role_policy_attachment.maintenance_policy_attachment_2, aws_iam_role_policy_attachment.maintenance_policy_attachment_1]


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
  image_id               = local.k8s_node_groups.fundamental.ami_id

  # Bootstrap user_data for CUSTOM AMI (when ami_id is specified)
  user_data = local.use_custom_ami ? base64encode(<<-USERDATA
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

${local.eks_bootstrap_mime_part}
--==MYBOUNDARY==--

USERDATA
  ) : null

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = "true"
      encrypted             = var.enable_ebs_kms ? "true" : "false"
      kms_key_id            = var.enable_ebs_kms ? var.ebs_kms_key_arn : null
      volume_size           = max(var.k8s_node_groups.index.disk_size, var.k8s_node_groups.fundamental.disk_size)
      volume_type           = "gp3"
    }
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
  user_data = base64encode(<<-USERDATA
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

${local.eks_bootstrap}
--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
echo "Running zilliz custom user data script"
disk_volume=$(lsblk -J -o NAME,MODEL,SIZE | jq -r '.blockdevices[] | select(.model != null and (.model | test("Amazon EC2 NVMe Instance Storage"))) | .name')
echo $${disk_volume}
if [ -n "$${disk_volume}" ] && lsblk | fgrep -q $${disk_volume}; then
    mkdir -p /mnt/data /var/lib/kubelet /var/lib/docker
    mkfs.xfs /dev/$${disk_volume}
    mount /dev/$${disk_volume} /mnt/data
    chmod 0755 /mnt/data
    mv /var/lib/kubelet /mnt/data/
    mv /var/lib/docker /mnt/data/
    ln -sf /mnt/data/kubelet /var/lib/kubelet
    ln -sf /mnt/data/docker /var/lib/docker
    UUID=$(lsblk -f | grep $${disk_volume} | awk '{print $$3}')
    echo "UUID=$$UUID     /mnt/data   xfs    defaults,noatime  1   1" >> /etc/fstab
fi
echo "mount results $(cat /etc/fstab)"
echo 'User data script done'

--==MYBOUNDARY==--

USERDATA
  )
  image_id = local.k8s_node_groups.search.ami_id
  vpc_security_group_ids = local.node_security_group_ids

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = "true"
      encrypted             = var.enable_ebs_kms ? "true" : "false"
      kms_key_id            = var.enable_ebs_kms ? var.ebs_kms_key_arn : null
      iops                  = 3000
      throughput            = 125
      volume_size           = var.k8s_node_groups.search.disk_size
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


# Determine AMI type for each node group:
# - set null  if provided ami_id
# - Otherwise auto-detect from instance type (ARM 'g' suffix -> AL2023_ARM_64_STANDARD, else AL2023_x86_64_STANDARD)
locals {
  ami_types = {
    for name, ng in var.k8s_node_groups : name => (
      ng.ami_id != null ? null : (
        can(regex("^[a-z]+[0-9]+g[a-z]*\\.", ng.instance_types)) ? "AL2023_ARM_64_STANDARD" : "AL2023_x86_64_STANDARD"
      )
    )
  }
}

# aws_eks_node_group.search: always created (max >= 1 guaranteed by data.tf)
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

# aws_eks_node_group.tiered: conditionally created when tiered is in node_quotas with max > 0
resource "aws_eks_node_group" "tiered" {
  count         = var.enable_tiered ? 1 : 0
  ami_type      = lookup(local.ami_types, "tiered", "AL2023_x86_64_STANDARD")
  capacity_type = var.k8s_node_groups["tiered"].capacity_type
  cluster_name  = local.eks_cluster_name

  instance_types = [
    var.k8s_node_groups["tiered"].instance_types,
  ]
  labels = {
    "zilliz-group-name" = "tiered"
    "node-role/tiered"  = "true"
    "node-role/milvus"  = "true"
  }
  node_group_name_prefix = "${local.prefix_name}-tiered-"
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
    desired_size = var.k8s_node_groups["tiered"].min_size
    max_size     = var.k8s_node_groups["tiered"].max_size
    min_size     = var.k8s_node_groups["tiered"].min_size
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
  # make it share the same AMI type as core node group
  ami_type      = local.ami_types.core
  capacity_type = "ON_DEMAND"
  cluster_name  = local.eks_cluster_name

  instance_types = [
    "t3.medium",
  ]
  labels = {
    "zilliz-group-name" = "init"
    "node-role/init"    = "true"
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

  depends_on = [aws_eks_addon.vpc-cni, aws_kms_grant.asg_ebs_kms_grant]
}
