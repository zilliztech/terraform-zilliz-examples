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
  # Tiered node quota from API (separate provider field, null when not enabled)
  tiered_node_quota = (
    data.zillizcloud_byoc_i_project_settings.this.tiered_node_quota != null
    ? { tiered = data.zillizcloud_byoc_i_project_settings.this.tiered_node_quota }
    : {}
  )

  k8s_node_groups = {
    for name, ng in merge(
      # Tiered placeholder (max_size=0 → count=0, not created unless API enables it)
      { tiered = { disk_size = 100, min_size = 0, max_size = 0, desired_size = 0, instance_types = "i4i.2xlarge", capacity_type = "ON_DEMAND" } },
      # API returns: core, index, search, fundamental
      data.zillizcloud_byoc_i_project_settings.this.node_quotas,
      # API tiered quota overwrites placeholder when present
      local.tiered_node_quota,
    ) : name => merge(ng, {
      ami_id    = lookup(var.k8s_node_group_image_id, name, null)
      disk_size = max(ng.disk_size, 100)
    })
  }

  # Placeholder has max_size=0, so this is false unless API returns tiered with max_size>0
  enable_tiered = local.k8s_node_groups["tiered"].max_size > 0
```

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

All of the changes in this step are in `modules/aws_byoc_i/eks/eks_nodegroup.tf`.

**5a.** Add a `tiered` entry to the existing `local.ami_types` block so the new node group can reuse the same AMI-selection logic as the others:

```hcl
locals {
  ami_types = {
    search      = can(regex("^[a-z]+[0-9]+g[a-z]*\\.", var.k8s_node_groups.search.instance_types)) ? "AL2023_ARM_64_STANDARD" : "AL2023_x86_64_STANDARD"
    core        = can(regex("^[a-z]+[0-9]+g[a-z]*\\.", var.k8s_node_groups.core.instance_types)) ? "AL2023_ARM_64_STANDARD" : "AL2023_x86_64_STANDARD"
    index       = can(regex("^[a-z]+[0-9]+g[a-z]*\\.", var.k8s_node_groups.index.instance_types)) ? "AL2023_ARM_64_STANDARD" : "AL2023_x86_64_STANDARD"
    fundamental = can(regex("^[a-z]+[0-9]+g[a-z]*\\.", var.k8s_node_groups.fundamental.instance_types)) ? "AL2023_ARM_64_STANDARD" : "AL2023_x86_64_STANDARD"
    # --- ADD THIS LINE ---
    # When the diskann launch template carries a custom image_id (e.g. FIPS AMI),
    # EKS requires ami_type to be null ("CUSTOM"). Fall back to null whenever the
    # caller provides a tiered AMI via var.k8s_node_group_image_id.
    tiered = lookup(var.k8s_node_group_image_id, "tiered", null) != null ? null : (
      can(regex("^[a-z]+[0-9]+g[a-z]*\\.", var.k8s_node_groups.tiered.instance_types)) ? "AL2023_ARM_64_STANDARD" : "AL2023_x86_64_STANDARD"
    )
  }
}
```

> If the EKS module doesn't already accept `var.k8s_node_group_image_id`, either thread it through from the root module or replace the `lookup(...)` call with your own equivalent. The point is: when the diskann launch template supplies an `image_id`, tiered's `ami_type` must be `null`.

**5b.** Append the following resource (for example, after the `search` node group):

```hcl
resource "aws_eks_node_group" "tiered" {
  count         = var.enable_tiered ? 1 : 0
  ami_type      = local.ami_types.tiered
  capacity_type = var.k8s_node_groups["tiered"].capacity_type
  cluster_name  = local.eks_cluster_name

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

## Step 6 — Enable Tiered Storage in Zilliz Cloud Console

1. Log in to the [Zilliz Cloud console](https://cloud.zilliz.com/).
2. In the top-right corner, select the correct **BYOC organization**.
3. Navigate to **Projects** and locate the project you want to enable tiered storage for.
4. Click the **"..."** button in the bottom-right corner of the project card, then click **View Project Details**.
5. In the **Resource Settings** section, click **Edit**.
6. In the dialog, check **Tiered** and click **Save** in the bottom-right corner.

After saving, the API will return a `tiered_node_quota` for this project.

## Step 7 — Verify

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

## Custom AMI (FIPS) Users — Extra Steps

If your cluster uses a custom AMI (for example, a FIPS-compliant image) and the `diskann` launch template carries a non-null `image_id`, AWS will reject node group creation with:

```
InvalidParameterException: You cannot specify an AMI Type other than CUSTOM,
when specifying an image id in your Launch template
```

Three things must be true for the tiered node group to use the custom AMI:

1. **`var.k8s_node_group_image_id` must include a `tiered` entry.** When you run `terraform apply`, pass the same AMI you are using for `search` (both share the `diskann` launch template), for example:

   ```hcl
   k8s_node_group_image_id = {
     search = "ami-015074ee112ce706a"
     tiered = "ami-015074ee112ce706a"
     # ... other node groups as needed
   }
   ```

2. **`local.ami_types.tiered` must resolve to `null`** when an override is set. The `lookup(var.k8s_node_group_image_id, "tiered", null)` check in Step 5a handles this automatically — tiered's `ami_type` becomes `null` (i.e. `CUSTOM`) as soon as you pass a tiered AMI, matching what EKS expects when the launch template supplies an `image_id`.

3. **The `diskann` launch template userdata must run the NVMe mount *before* `${local.eks_bootstrap}`.** When EKS uses a custom AMI, kubelet is started by the bootstrap command you embed in userdata — not by EKS. If the NVMe mount script runs after kubelet has already started, `/var/lib/kubelet` is already on the EBS root volume and the symlink swap has no effect, so ephemeral storage ends up sized to the 100 GB root disk instead of the ~1.8 TB NVMe. Worse, if `${local.eks_bootstrap}` appears *outside* the `multipart/mixed` MIME part it will be silently ignored and the node will fail to register.

   The correct layout for the `aws_launch_template.diskann` userdata heredoc:

   ```hcl
   user_data = base64encode(<<-USERDATA
   MIME-Version: 1.0
   Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

   --==MYBOUNDARY==
   Content-Type: text/x-shellscript; charset="us-ascii"

   #!/bin/bash
   echo "Running zilliz NVMe mount script"
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
   echo 'NVMe mount done'
   ${local.eks_bootstrap}
   --==MYBOUNDARY==--

   USERDATA
   )
   ```

   Key points:
   - `${local.eks_bootstrap}` is **inside** the MIME part, **after** the NVMe mount — never above the `--==MYBOUNDARY==` header.
   - `$${...}` escapes bash variables so Terraform doesn't try to interpolate them; `${local.eks_bootstrap}` is a real Terraform interpolation.
   - Verify on a running node: `df -h /var/lib/kubelet` should show a ~1.8 TB mount backed by the NVMe device, and `kubectl describe node` should report ephemeral-storage in the same range.
