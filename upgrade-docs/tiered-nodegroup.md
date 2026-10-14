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

## Step 3 — Update EKS Module

Copy the latest `modules/aws_byoc_i/eks/` directory from the master branch of [terraform-zilliz-examples](https://github.com/zilliztech/terraform-zilliz-examples) to replace your local copy. This adds the tiered node group resource, `enable_tiered` variable, and updated validation rules.

## Step 4 — Pass `enable_tiered` to the EKS Module

In your root `main.tf`, add the argument to the `module "eks"` block:

```hcl
module "eks" {
  # ... existing arguments ...
  enable_tiered = local.enable_tiered
}
```

## Step 5 — Enable Tiered Storage in Zilliz Cloud Console

1. Log in to the [Zilliz Cloud console](https://cloud.zilliz.com/).
2. In the top-right corner, select the correct **BYOC organization**.
3. Navigate to **Projects** and locate the project you want to enable tiered storage for.
4. Click the **"..."** button in the bottom-right corner of the project card, then click **View Project Details**.
5. In the **Resource Settings** section, click **Edit**.
6. In the dialog, check **Tiered** and click **Save** in the bottom-right corner.

After saving, the API will return a `tiered_node_quota` for this project.

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

2. **`local.ami_types.tiered` must resolve to `null`** when an override is set. The `lookup(var.k8s_node_group_image_id, "tiered", null)` check in the EKS module handles this automatically — tiered's `ami_type` becomes `null` (i.e. `CUSTOM`) as soon as you pass a tiered AMI, matching what EKS expects when the launch template supplies an `image_id`.

3. **The `diskann` launch template userdata must prepare NVMe before EKS bootstrap.** Keep the storage setup as the first shell-script MIME part and `${local.eks_bootstrap}` after it, before the closing MIME boundary. The custom AMI bootstrap local already includes its own MIME-part header.

   Use the complete userdata block and `scripts/mount-nvme.sh` from
   `modules/aws_byoc_i/eks` together. The userdata installs and starts
   `zilliz-mount-nvme.service` before the `${local.eks_bootstrap}`
   MIME part. Its systemd dependencies also prepare storage before nodeadm configuration,
   kubelet, containerd, and Docker on subsequent boots.

   The service mounts the instance-store disk on every boot and initializes its
   directories only when `/mnt/data/.initialized` is absent. Stop/start clears
   the instance store, including this marker, so initialization runs again.
   An ordinary reboot preserves the filesystem and marker. Do not persist an
   instance-store UUID in `/etc/fstab` or place the marker on the EBS root disk.

   This launch-template update applies to newly launched nodes. Existing warm
   instances retain their installed script and fstab; updating the template
   alone does not repair them. Plan their replacement through the managed node
   group lifecycle before validating repeated suspend/resume cycles.

   Key points:
   - `${local.eks_bootstrap}` remains **after** the NVMe setup part and **before** the closing MIME boundary.
   - The shell script is included with `file()`; its shell variables are not recursively interpreted by Terraform.
   - Verify on a running node: `df -h /var/lib/kubelet` should show a ~1.8 TB mount backed by the NVMe device, and `kubectl describe node` should report ephemeral-storage in the same range.
