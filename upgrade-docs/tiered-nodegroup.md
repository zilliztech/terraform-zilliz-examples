# Enabling Tiered Storage Node Group for Existing BYOC-I Clusters

This guide is for users who have already deployed a BYOC-I cluster using a previous version of the examples and now want to enable **tiered storage**.

## Prerequisites

- Zilliz has enabled tiered storage for your project (the API returns a `tiered_node_quota` field).
- Terraform provider `zillizcloud` version `>= 0.6.30`.

## Option A: Manage via Terraform (Recommended)

Best for users who maintain their own copy of the Terraform examples and want the tiered node group tracked in Terraform state.

### Step 1 — Upgrade the Provider

Update the version constraint in your `versions.tf` or `required_providers` block:

```hcl
zillizcloud = {
  source  = "zilliztech/zillizcloud"
  version = ">= 0.6.30"
}
```

### Step 2 — Update `data.tf`

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

### Step 3 — Update EKS Module Variables

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

### Step 4 — Pass `enable_tiered` to the EKS Module

In your root `main.tf`, add the argument to the `module "eks"` block:

```hcl
module "eks" {
  # ... existing arguments ...
  enable_tiered = local.enable_tiered
}
```

### Step 5 — Add the Tiered Node Group Resource

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

### Step 6 — Verify

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

---

## Option B: Automatic Creation by Zilliz Agent (Zero Code Changes)

Best for users who prefer not to modify their Terraform code. The Zilliz infra-agent creates the tiered node group automatically using the existing maintenance IAM role.

### IAM Permission Update Required

The maintenance role already has `eks:CreateNodegroup` permission. However, the agent also needs to read the EKS node role when creating a node group. Add the following statement to `maintenance_policy_2` in `modules/aws_byoc_i/eks/iam-role-maintenance.tf`:

Find the `S3CheckBucketLocation` statement in `maintenance_policy_2`, and add the new block **after** it:

```hcl
      {
        "Sid" : "S3CheckBucketLocation",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetBucketLocation"
        ],
        "Resource" : "arn:aws:s3:::${local.bucket_id}"
      },
      # ---- ADD THIS BLOCK ----
      {
        "Sid" : "IAMReadNodeRole",
        "Effect" : "Allow",
        "Action" : [
          "iam:GetRole",
          "iam:ListAttachedRolePolicies"
        ],
        "Resource" : [
          "arn:aws:iam::*:role/${local.eks_role_name}",
          "arn:aws:iam::*:role/${local.minimal_node_role_name}",
          "arn:aws:iam::*:role/aws-service-role/eks-nodegroup.amazonaws.com/AWSServiceRoleForAmazonEKSNodegroup"
        ]
      }
```

`local.eks_role_name` and `local.minimal_node_role_name` are already defined in the EKS module's `locals.tf` and resolve to the actual role names used by your cluster.

> **Tip:** This is the only change from [PR #129](https://github.com/zilliztech/terraform-zilliz-examples/pull/129). You can cherry-pick just this IAM update and run `terraform apply`.

### What to Do

1. **Update IAM permissions** — Add the `IAMReadNodeRole` statement above to your maintenance policy, then run `terraform apply` to deploy the IAM change.
2. **Contact Zilliz to enable tiered storage** — Once the backend configuration is in place, the infra-agent will automatically:
   - Detect the tiered node quota.
   - Read the node role via `iam:GetRole` to configure the new node group.
   - Call the EKS `CreateNodegroup` API via the maintenance role.
   - Provision the tiered node group using the existing launch template (with NVMe mount configuration).
3. **No other Terraform changes required.**

### Caveats

- The tiered node group is **not tracked in Terraform state**. Running `terraform plan` will not show it, and `terraform apply` will not modify it.
- If you later decide to manage it via Terraform, you can import it:

  ```bash
  terraform import 'aws_eks_node_group.tiered[0]' \
    <cluster-name>:<node-group-name>
  ```

  You must first add the corresponding Terraform resource definition (see Option A, Step 5).

---

## Comparison

| | Option A: Terraform | Option B: Agent |
|---|---|---|
| Code changes | ~5 files, ~60 lines | IAM policy only (~15 lines) |
| State management | Tiered node group in Terraform state | Not in state |
| Auditability | Preview with `terraform plan` | Check agent logs |
| Rollback | `terraform destroy -target` | Manual or agent-initiated |
| Best for | Teams that maintain IaC governance | Quick enablement, minimal changes |
| IAM requirement | Standard (Terraform already has permissions) | Maintenance role needs `CreateNodegroup` + `iam:GetRole` |
