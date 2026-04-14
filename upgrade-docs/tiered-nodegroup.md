# Enabling Tiered Storage Node Group for Existing BYOC-I Clusters

This guide is for users who have already deployed a BYOC-I cluster using a previous version of the examples and now want to enable **tiered storage**.

## Prerequisites

- Zilliz has enabled tiered storage for your project (the API returns a `tiered_node_quota` field).
- Terraform provider `zillizcloud` version `>= 0.6.34`.

## Step 1 — Upgrade the Provider

Update the version constraint in your `versions.tf` or `required_providers` block. Note that Terraform's `~>` constraint does **not** match pre-release versions, so pin explicitly if you are testing an `-rc` build:

```hcl
zillizcloud = {
  source  = "zilliztech/zillizcloud"
  version = ">= 0.6.34"
}
```

## Step 2 — Update `data.tf`

In your `locals {}` block, replace the existing `k8s_node_groups` assignment:

```hcl
# Remove this line:
k8s_node_groups = data.zillizcloud_byoc_i_project_settings.this.node_quotas
```

With the following merge logic:

```hcl
  # Default for the tiered node group.
  # max_size = 0 means the node group will not be created unless the API provides a quota.
  _tiered_default = {
    tiered = {
      disk_size      = 100
      min_size       = 0
      max_size       = 0
      desired_size   = 0
      instance_types = "m6i.2xlarge"
      capacity_type  = "ON_DEMAND"
    }
  }

  # Pull the tiered quota from the provider when available.
  _tiered_from_api = (
    data.zillizcloud_byoc_i_project_settings.this.tiered_node_quota != null
    ? { tiered = data.zillizcloud_byoc_i_project_settings.this.tiered_node_quota }
    : {}
  )

  k8s_node_groups = {
    for name, ng in merge(
      local._tiered_default,
      data.zillizcloud_byoc_i_project_settings.this.node_quotas,
      local._tiered_from_api,
    ) : name => merge(ng, {
      # Tiered instances (e.g. i4i) use NVMe local disks; the API may return disk_size = 0.
      # Floor to 100 GB so the EBS root volume has a sensible size.
      disk_size = ng.disk_size > 0 ? ng.disk_size : 100
    })
  }

  enable_tiered = (
    data.zillizcloud_byoc_i_project_settings.this.tiered_node_quota != null
    && local.k8s_node_groups["tiered"].max_size > 0
  )
```

> **Note:** If your code uses a custom AMI variable (e.g. `var.k8s_node_group_image_id`), you can add
> `ami_id = lookup(var.k8s_node_group_image_id, name, null)` inside the inner `merge(ng, { ... })` block.

## Step 3 — Update EKS Module Variables

Open `modules/aws_byoc_i/eks/variables.tf` and make the following changes.

**3a.** Relax the `max_size` validation from `> 0` to `>= 0` (tiered may have `max_size = 0` when disabled):

```hcl
  validation {
    condition = alltrue([
      for k, v in var.k8s_node_groups :
      v.disk_size > 0 &&
      v.min_size >= 0 &&
      v.max_size >= 0 &&          # was: v.max_size > 0
      v.desired_size >= 0 &&
      v.desired_size <= v.max_size &&
      contains(["ON_DEMAND", "SPOT"], v.capacity_type)
    ])
    error_message = "Invalid node group configuration."
  }
```

**3b.** Add the `enable_tiered` variable:

```hcl
variable "enable_tiered" {
  description = "Whether to create the tiered node group."
  type        = bool
  default     = false
}
```

## Step 4 — Pass `enable_tiered` to the EKS Module

In your root `main.tf`, add the argument to the `module "eks"` block:

```hcl
module "eks" {
  # ... existing arguments ...
  enable_tiered = local.enable_tiered
}
```

## Step 5 — Add the Tiered Node Group Resource

In `modules/aws_byoc_i/eks/eks_nodegroup.tf`, append the following resource (for example, after the `search` node group):

```hcl
resource "aws_eks_node_group" "tiered" {
  count         = var.enable_tiered ? 1 : 0
  capacity_type = var.k8s_node_groups["tiered"].capacity_type
  cluster_name  = local.eks_cluster_name

  # Auto-detect AMI type from instance architecture
  ami_type = (
    can(regex("^[a-z]+[0-9]+g[a-z]*\\.", var.k8s_node_groups["tiered"].instance_types))
    ? "AL2023_ARM_64_STANDARD"
    : "AL2023_x86_64_STANDARD"
  )

  instance_types = [var.k8s_node_groups["tiered"].instance_types]

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

  # Reuses the "diskann" launch template (includes NVMe mount user-data)
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
```

## Step 6 — Verify

```bash
terraform init -upgrade
terraform plan
```

Expected plan output:

| Scenario | Expected Result |
|---|---|
| Tiered storage **not enabled** | No new resources (`enable_tiered = false`, `count = 0`) |
| Tiered storage **enabled** | `aws_eks_node_group.tiered[0]` will be created (1 to add) |

Existing resources should show **no destroy or recreate** actions.
