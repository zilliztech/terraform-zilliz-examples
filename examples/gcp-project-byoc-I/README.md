# GCP BYOC-I Deployment

This example provisions a GCP BYOC-I dataplane with customer-managed infrastructure and a short-lived GCE VM booter. The Terraform runner does not need network access to the private GKE API server.

## What It Creates

- VPC-native GKE networking, Cloud NAT, and firewall rules
- GCS bucket for dataplane storage
- GKE private regional cluster and node pools from BYOC-I quota settings, or dedicated BYOC-I node pools in an existing compatible cluster
- GCP service accounts for GKE nodes, maintenance, storage, and the booter VM
- Optional Private Service Connect endpoint
- Short-lived GCE booter VM that uses the configured booter service account to install `cloud-agent` into GKE, then self-deletes after a TTL
- Per-dataplane Resource Manager tag for tag-scoped booter self-delete permissions by default
- `zillizcloud_byoc_i_project_agent` and `zillizcloud_byoc_i_project`

## Requirements

- Terraform `>= 1.6.0`
- Google provider `~> 6.32.0`
- Zilliz Cloud provider version that includes `zillizcloud_byoc_i_project.gcp`
- A GCP project with the APIs needed for Artifact Registry, Compute Engine, Cloud DNS, GKE, IAM, Service Usage, and Cloud Storage
- By default, the Terraform runner needs `roles/resourcemanager.tagAdmin` and `roles/resourcemanager.tagUser` to create and bind Resource Manager tags
- For Private Service Connect, `gcp_psc_service_attachment_id` is optional. When unset, it defaults to `projects/vdc-dev-test/regions/<region>/serviceAttachments/zilliz-byoc-psc-dns` for `env = "UAT"` and `projects/vdc-prod/regions/<region>/serviceAttachments/zilliz-byoc-psc-dns` otherwise.

## Usage

```bash
cp terraform.sample.tfvars terraform.tfvars
terraform init
terraform plan
terraform apply
```

The booter VM receives the BYOC-I agent token through Terraform-managed VM metadata. This is intentional for v1 and means the token is visible in Terraform state and VM metadata.

The GCP region is read from `zillizcloud_byoc_i_project_settings`. Set `gcp_project_id` in `terraform.tfvars`.

Default resource names use the prefix `zilliz-dp-<last-12-chars-of-data_plane_id>`. For example, the default VPC, GKE cluster, booter VM, and bucket names are derived from that prefix. If you already deployed this example with older random-suffix names, set the `customer_*` name variables to the existing resource names before applying this version.

## Network Modes

Network ownership and resource lifecycle are controlled independently:

| Variable | Values | Purpose |
|---|---|---|
| `network_project_id` | empty or a project ID | Empty uses `gcp_project_id`; a different project selects a Shared VPC host project |
| `vpc_mode` | `create`, `existing` | Create a dedicated VPC or read an existing VPC |
| `subnet_mode` | `create`, `existing` | Create the primary GKE subnet and secondary ranges, or read an existing subnet |
| `lb_subnet_mode` | `create`, `existing`, `disabled` | Create, read/discover, or omit the regional managed proxy subnet |
| `create_cloud_nat` | `true`, `false` | Create dedicated Router/NAT resources, or use existing egress |
| `create_firewall_rules` | `true`, `false` | Create BYOC-I firewall rules, or let the customer manage them |
| `manage_shared_vpc_iam` | `true`, `false` | Manage the GKE service-agent grants in the Shared VPC host project |

Terraform never manages the lifecycle of a VPC or subnet selected with an `existing` mode. Destroy only removes resources that this configuration created.

## GKE Cluster Modes

`gke_mode = "create"` is the default and creates both the private regional cluster and its BYOC-I node pools.

To reuse a customer-managed cluster while creating dedicated BYOC-I node pools:

```hcl
gke_mode                 = "existing"
customer_gke_cluster_name = "customer-gke"
```

The existing cluster must be regional in the BYOC-I region, VPC-native, use the selected VPC, primary subnet, Pod range, and Service range, have private nodes enabled, and use the workload identity pool `<gcp_project_id>.svc.id.goog`. If GKE Secrets encryption validation is enabled, `gke_secrets_kms_key_name` must identify the key already configured on the cluster.

In `existing` mode Terraform does not modify or own the cluster. `terraform destroy` preserves it and removes only the BYOC-I node pools and other resources created by this configuration. Reusing existing node pools is not supported.

## Service Account and IAM Modes

By default, Terraform creates four dedicated service accounts and manages their custom roles and IAM bindings:

```hcl
service_account_mode = "create"
manage_iam           = true
```

To use customer-created service accounts while allowing Terraform to manage their permissions:

```hcl
service_account_mode = "existing"
manage_iam           = true

customer_gke_node_service_account_name   = "customer-zilliz-node"
customer_management_service_account_name = "customer-zilliz-maintenance"
customer_storage_service_account_name    = "customer-zilliz-storage"
customer_booter_service_account_name     = "customer-zilliz-booter"
```

When the Terraform runner cannot manage IAM, the customer must create the accounts, custom roles, project IAM bindings, and Workload Identity bindings before apply:

```hcl
service_account_mode = "existing"
manage_iam           = false

customer_gke_node_service_account_name   = "customer-zilliz-node"
customer_management_service_account_name = "customer-zilliz-maintenance"
customer_storage_service_account_name    = "customer-zilliz-storage"
customer_booter_service_account_name     = "customer-zilliz-booter"

manage_shared_vpc_iam         = false
grant_gcs_kms_key_iam         = false
grant_gke_secrets_kms_key_iam = false
```

All four service account fields must reference accounts that exist in `gcp_project_id`; multiple fields can reference the same account. Terraform reads the accounts to obtain their canonical email and resource name but does not modify them when `manage_iam` is false.

The customer-managed IAM configuration must provide the permissions defined in [`modules/gcp_byoc_i/iam/iam.tf`](../../modules/gcp_byoc_i/iam/iam.tf) and [`modules/gcp_byoc_i/workload-identity/main.tf`](../../modules/gcp_byoc_i/workload-identity/main.tf), including:

- GKE node logging, monitoring, and default node service account permissions.
- Maintenance cluster update, operation read, project metadata read, and optional managed-instance-group resize permissions.
- Storage object/bucket access and storage/maintenance Workload Identity bindings. The `<gcp_project_id>.svc.id.goog` pool only exists once the project has a Workload Identity enabled GKE cluster, so these bindings must be created after the cluster.
- Booter Kubernetes bootstrap, VM self-delete, and zone-operation read permissions.
- `roles/iam.serviceAccountUser` from the maintenance service account to the node service account.

The Terraform runner still needs `iam.serviceAccounts.actAs` on the existing GKE node and booter service accounts so it can attach them to node pools and the booter VM. Read access to the four service accounts is also required.

When `manage_iam` is false and Resource Manager tags remain enabled, provide customer-created `vendor_tag_key_id` and `vendor_tag_value_id` values so the customer can preconfigure the booter self-delete IAM condition. Alternatively set `enable_resource_manager_tags = false` and scope the preconfigured permission to the exact booter VM resource name. Leaving tag IDs empty asks Terraform to create them and is unsuitable when the runner cannot manage tags or the IAM condition must be configured before apply.

Do not switch an already-applied configuration directly from `create` to `existing`: removing managed service-account resources from configuration would plan their destruction. Remove the four service accounts and managed IAM resources from the Terraform state first, after verifying that the customer has recreated or adopted all required permissions. New configurations using customer-created accounts can select `existing` immediately.

## GCS Bucket Modes

`bucket_mode = "create"` is the default and creates a dedicated GCS bucket managed by this Terraform configuration.

To reuse a customer-managed bucket without modifying or owning its lifecycle:

```hcl
bucket_mode          = "existing"
customer_bucket_name = "customer-existing-bucket"
```

The bucket must already exist and be accessible to the Terraform runner. In `existing` mode, Terraform reads the bucket and still configures the BYOC-I storage IAM permissions against it, but does not change bucket settings, labels, encryption, or lifecycle. `enable_gcs_kms` must remain `false`; configure encryption on the existing bucket outside this example.

Do not switch a bucket already managed in this state directly from `create` to `existing`, because Terraform would plan to destroy the managed resource. Remove it from state first with `terraform state rm module.gcs.google_storage_bucket.this[0]`, then change the mode.

For a customer security baseline that uses the Regular release channel, Binary Authorization, Identity Service, intra-node visibility, Shielded VM protections, and managed node upgrades, set:

```hcl
gke_release_channel                      = "REGULAR"
gke_binary_authorization_evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
gke_enable_identity_service              = true
gke_enable_intranode_visibility          = true
gke_node_enable_secure_boot              = true
gke_node_enable_integrity_monitoring     = true
gke_node_auto_repair                     = true
gke_node_auto_upgrade                    = true
```

These settings apply when Terraform creates the cluster or its dedicated BYOC-I node pools. Node machine types come from the BYOC-I node-group quotas returned by Zilliz Cloud. By default, counts and disk sizes also come from those quotas, and quota-derived node disks have a minimum size of 100 GiB.

To override the node settings for every BYOC-I node pool, set:

```hcl
gke_node_initial_count = 1
gke_node_disk_size_gb  = 30
gke_node_image_type    = "COS_CONTAINERD"
```

Machine type always comes from each Zilliz Cloud node-group quota. When the remaining overrides are unset, initial size also comes from the node-group quota, the quota disk size is subject to a 100 GiB minimum, and the image type defaults to `COS_CONTAINERD`.

`gke_workload_pool` can be passed explicitly, but GKE requires it to be `<gcp_project_id>.svc.id.goog`. When empty, Terraform derives that value automatically. `gcp_region` can also be passed explicitly but must match the region configured for the Zilliz Cloud dataplane.

Identity Service for GKE is deprecated and is not supported in GKE 1.37 or later or in Google Cloud organizations created on or after July 1, 2025. Enable `gke_enable_identity_service` only when the customer environment still supports it; prefer Workforce Identity Federation for new deployments.

### Create a Dedicated VPC and Subnets

This is the default and is backward compatible:

```hcl
vpc_mode       = "create"
subnet_mode    = "create"
lb_subnet_mode = "create"
vpc_cidr       = "10.0.0.0/16"
```

### Existing VPC with New Dedicated Subnets

```hcl
vpc_mode          = "existing"
customer_vpc_name = "customer-vpc"
subnet_mode       = "create"
lb_subnet_mode    = "create"

primary_subnet = {
  name = "zilliz-primary"
  cidr = "10.20.0.0/20"
}
pod_subnet = {
  name = "zilliz-pods"
  cidr = "10.24.0.0/14"
}
service_subnet = {
  name = "zilliz-services"
  cidr = "10.28.0.0/20"
}
lb_subnet = {
  name = "zilliz-lb-proxy"
  cidr = "10.29.0.0/23"
}
```

### Existing VPC and Existing Subnets

The existing primary subnet must be in the BYOC-I region and contain the named Pod and Service secondary ranges. The existing LB subnet must have purpose `REGIONAL_MANAGED_PROXY`.

```hcl
vpc_mode          = "existing"
customer_vpc_name = "customer-vpc"
subnet_mode       = "existing"
lb_subnet_mode    = "existing"

primary_subnet = {
  name = "customer-gke-subnet"
}
pod_subnet = {
  name = "customer-pods"
}
service_subnet = {
  name = "customer-services"
}
lb_subnet = {
  name = "customer-lb-proxy"
}

# Disable these when the customer network already supplies egress and firewall policy.
create_cloud_nat      = false
create_firewall_rules = false
```

### Shared VPC

Set `network_project_id` to the Shared VPC host project. The VPC must already exist and the service project must already be attached to the host project. Both new-subnet and existing-subnet modes are supported.

Shared VPC with a new dedicated subnet:

```hcl
gcp_project_id     = "customer-service-project"
network_project_id = "customer-host-project"

vpc_mode          = "existing"
customer_vpc_name = "shared-vpc"
subnet_mode        = "create"
lb_subnet_mode     = "create"

primary_subnet = {
  name = "zilliz-primary"
  cidr = "10.20.0.0/20"
}
pod_subnet = {
  name = "zilliz-pods"
  cidr = "10.24.0.0/14"
}
service_subnet = {
  name = "zilliz-services"
  cidr = "10.28.0.0/20"
}
lb_subnet = {
  name = "zilliz-lb-proxy"
  cidr = "10.29.0.0/23"
}
```

For existing Shared VPC subnets, change both subnet modes to `existing` and provide the existing subnet and secondary-range names as shown in the previous example.

With `manage_shared_vpc_iam = true`, Terraform grants the service project's GKE service agent `roles/container.hostServiceAgentUser` in the host project and grants the GKE and Cloud Services service agents `roles/compute.networkUser` on the primary subnet. Set it to `false` when those grants are centrally managed. The Terraform runner needs permission to read the host VPC and to manage any host-project subnet, NAT, firewall, DNS, or IAM resources enabled by the selected modes.

If multiple GCP BYOC-I VPCs need VPC Peering, configure non-overlapping `vpc_cidr` values and unique GKE private control plane ranges with `master_ipv4_cidr_block`. The default control plane range is `172.16.0.0/28`; a second peered environment can use a different `/28`, such as `172.16.0.16/28`.

The example outputs `primary_subnet_cidr`, `pod_subnet_cidr`, `service_subnet_cidr`, `lb_subnet_cidr`, and `master_ipv4_cidr_block` to make VPC Peering overlap checks and firewall source range setup explicit.

The PSC service attachment ID can be overridden with `gcp_psc_service_attachment_id`. When it is not set, Terraform builds the ID from the current BYOC-I project region and environment.

The example grants the storage service account to the fixed BYOC-I Kubernetes service accounts used by Loki and Milvus bootstrap through GKE Workload Identity. It also grants storage Workload Identity access to the target GKE cluster because instance namespaces and service accounts are created at runtime.

The booter VM uses the configured booter service account, which can be shared with other roles in existing-account mode. The Zilliz BYOC organization service account is not granted permission to impersonate the maintenance service account. The in-cluster `infra/infra-agent-sa` Kubernetes service account uses GKE Workload Identity to access the maintenance service account instead.

### GCS Bucket CMEK

The GCS bucket uses Google-managed encryption by default. To use a customer-managed Cloud KMS key for new bucket objects, enable CMEK:

```hcl
enable_gcs_kms = true
```

When `gcs_kms_key_name` is empty, Terraform creates a Cloud KMS key ring and crypto key in the BYOC-I region and uses that key for the bucket. The generated KMS resource names are derived from the bucket name.

To use an existing Cloud KMS key instead, pass the full key resource name:

```hcl
gcs_kms_key_name = "projects/<gcp-project-id>/locations/<region>/keyRings/<key-ring>/cryptoKeys/<key>"
```

Terraform-created KMS keys are automatically granted to the bucket project's Cloud Storage service agent. When using an existing key, `grant_gcs_kms_key_iam = true` default grants the same `roles/cloudkms.cryptoKeyEncrypterDecrypter` permission on that key. The Terraform runner must be allowed to manage IAM on the KMS key. If the permission is already granted outside Terraform for an existing key, set:

```hcl
grant_gcs_kms_key_iam = false
```

The KMS key location must be compatible with the bucket location. Changing the bucket default KMS key affects new objects written after the change; existing objects are not automatically re-encrypted.

### GKE Application-layer Secrets Encryption

Kubernetes Secrets stored in GKE etcd use Google-managed encryption by default. To add application-layer envelope encryption with a customer-managed Cloud KMS key, enable:

```hcl
enable_gke_secrets_encryption = true
```

When `gke_secrets_kms_key_name` is empty, Terraform creates a key ring and crypto key in the GKE region. The generated key names are derived from the GKE cluster name.

To use an existing key instead, provide its full resource name:

```hcl
gke_secrets_kms_key_name = "projects/<gcp-project-id>/locations/<region>/keyRings/<key-ring>/cryptoKeys/<key>"
```

The key location must match the GKE region. Terraform grants the Service Project GKE Service Agent:

```text
service-<SERVICE_PROJECT_NUMBER>@container-engine-robot.iam.gserviceaccount.com
```

the following role on the exact crypto key:

```text
roles/cloudkms.cryptoKeyEncrypterDecrypter
```

If an existing key is managed outside this Terraform configuration and the permission is already present, set:

```hcl
grant_gke_secrets_kms_key_iam = false
```

This setting encrypts Kubernetes Secrets stored in GKE etcd. It does not configure node disk CMEK or GCS bucket encryption. Enabling or changing the key on an existing cluster updates the GKE cluster; review the Terraform plan before applying.

### Disk CMEK and key protection levels

PVC disks, GKE node boot disks (including the temporary default pool), and the
booter boot disk share the existing PD KMS configuration and one IAM binding:

```hcl
enable_pd_kms = true
# Supply an existing regional key, or leave empty to create one shared disk key.
pd_kms_key_name = "projects/<key-project>/locations/<region>/keyRings/<ring>/cryptoKeys/<key>"
# Set false only for a supplied key whose Compute Engine service agent is already authorized.
grant_pd_kms_key_iam = true
```

The key location must match the deployment region. The principal is
`service-<deployment-project-number>@compute-system.iam.gserviceaccount.com`
and requires `roles/cloudkms.cryptoKeyEncrypterDecrypter` on the key. Cross-project
keys require permission to manage the key's IAM when automatic grants are enabled.
Module-created keys are always granted to the Compute Engine service agent.

The default `enable_pd_kms = false` leaves disk CMEK disabled. A supplied key alone
does not enable encryption. There is no separate boot-disk key or IAM switch.
**Existing deployments with `enable_pd_kms = true` will also enable boot-disk CMEK
after this upgrade, potentially replacing node pools and the booter.** Review the
plan and schedule disruption before applying. Disabling this option affects both
PVC and boot-disk configuration and removes the module-managed key/grant as applicable.

GKE Secrets encryption remains independent and covers etcd secrets only. Existing
compliant keys, including EKM keys, can be reused subject to service and organization
policy requirements; EKM infrastructure is not provisioned by this example.

For keys created by these modules, protection level is independently configurable:

```hcl
gcs_kms_protection_level         = "HSM"
pd_kms_protection_level          = "HSM"
gke_secrets_kms_protection_level = "HSM"
```

All three default to `SOFTWARE`; supported creation options are `SOFTWARE` and
`HSM`. These settings do not modify keys supplied by resource name. EKM setup is
not provisioned by this example. Review organization policy and the Terraform plan
before changing any existing key configuration; no automatic key migration is provided.

### Optional Local SSD replacement

Local SSD cannot use CMEK. If your environment disallows it, replace the search
pool's local ephemeral storage with a suitably sized boot disk:

```hcl
gke_node_group_local_ssd_counts = { search = 0 }
gke_node_group_disk_overrides = {
  search = { disk_size_gb = 1500, disk_type = "pd-ssd" }
}
```

Overrides are merged with `search=4, tiered=8`; specifying only search leaves tiered
unchanged. Zero omits the Local SSD configuration. For an enabled tiered pool also
requiring replacement, set `tiered=0` and provide a tiered boot disk override
(original raw Local SSD capacity is 3000 GiB).

Boot disk override precedence is per-pool override, then the global
`gke_node_disk_size_gb`, then the existing node-group disk size with its 100 GiB
minimum. Supported overrides are `pd-standard`, `pd-balanced`, `pd-ssd`, and `hyperdisk-balanced` on
compatible machines. For a pool configured with an N4 machine (for example
`n4-standard-16`), select Hyperdisk Balanced explicitly:

```hcl
gke_node_group_local_ssd_counts = { search = 0 }
gke_node_group_disk_overrides = {
  search = { disk_size_gb = 1500, disk_type = "hyperdisk-balanced" }
}
```

This disk override does not change the pool's machine type. N2 cannot use a
Hyperdisk boot disk; N4 requires Hyperdisk Balanced among the supported options.
Checks use the effective disk type for every enabled pool, including defaults.
See [Google's Hyperdisk Balanced compatibility guide](https://docs.cloud.google.com/compute/docs/disks/hd-types/hyperdisk-balanced).
IOPS and throughput use provider/service defaults; explicit performance controls
are outside this change.

Without Local SSD, disk-backed `emptyDir` uses the boot disk. OS, images, logs and
GKE reservations share this capacity, so 1500 GiB raw does not mean 1500 GiB of Pod
allocatable storage. Omitting the disk override can leave the pool on a small
`pd-balanced` boot disk. Existing DiskANN scheduling labels are retained; validate
published resource quotas, Pod scheduling and workload performance before production.

The temporary default pool's boot key is applied only on cluster creation; later
key changes are ignored on that removed pool to avoid replacing the GKE cluster.
Standalone node pools continue to manage their boot key normally.

Changing boot disk CMEK or removing Local SSD can replace nodes/node pools or the
booter. Review the replacement list in the plan and schedule any disruption.
These generic configuration options do not establish CRYPT3NS product support.

### Release channel and automatic upgrades

Defaults remain `gke_release_channel = "UNSPECIFIED"` and
`gke_node_auto_upgrade = false` to preserve existing behavior. Customers whose GKE
API rejects no-channel cluster creation can explicitly opt in:

```hcl
gke_release_channel   = "REGULAR"
gke_node_auto_upgrade = true
```

Selecting a release channel requires opting into automatic node upgrades in this
module. Upgrades can affect workloads. Leaving node auto-upgrade disabled is not a
guarantee that GKE will never perform a mandatory maintenance or end-of-support upgrade.

The booter image is not required in `terraform.tfvars`. Production defaults to `gcr.io/zilliz-byoc-prod/gcp-byoc-i-booter:latest`; UAT defaults to `gcr.io/zilliz-byoc-uat/gcp-byoc-i-booter:latest`. To use a customer-owned image repository for both the booter and cloud-agent images, set `image_repo_url` to the repository base URL without image name or tag:

```hcl
image_repo_url = "us-docker.pkg.dev/<gcp-project-id>/<repository>"
```

Terraform will use `<image_repo_url>/gcp-byoc-i-booter:latest` for the booter VM and `<image_repo_url>/cloud-agent:<agent_tag>` for cloud-agent when the Zilliz project settings provide an agent tag. If `booter_image` is set, it remains a full-image override for the booter and takes precedence over `image_repo_url`.

For booter troubleshooting, set `booter_print_serial_logs_on_apply = true` to print the booter VM serial console logs during `terraform apply`. This requires `gcloud` to be installed and authenticated on the Terraform runner.

Resource Manager tags are enabled by default. When no tag IDs are provided, Terraform creates a per-dataplane tag key derived from `data_plane_id` and a `booter` tag value, so multiple BYOC-I dataplanes can be created in the same GCP project without sharing a fixed project-level tag key. If your Terraform runner cannot manage tags, either set both `vendor_tag_key_id` and `vendor_tag_value_id` to use a pre-created tag, or set `enable_resource_manager_tags = false`. With tags enabled, booter self-delete permission is scoped to the exact booter VM instance name plus the Resource Manager tag. When tags are disabled, booter self-delete permission is scoped to the exact booter VM instance name only.

When Private Service Connect is enabled, the default `agent_server_host` uses `cloud-tunnel.gcp-<region>.byoc.<env_domain>`. Terraform creates Cloud DNS private A records for `cloud-tunnel.gcp-<region>.byoc.<env_domain>` and `cloud-open-api.gcp-<region>.byoc.<env_domain>` that point to the PSC endpoint IP. The booter chart also renders `hostAliases` for `cloud-agent` and `cloud-agent-backup`, so the configured `agent_server_host` resolves to the PSC endpoint IP inside those pods. Set `enable_private_dns = false` if the customer VPC already manages these private records externally.

If the provider version has not been released yet, use a local Terraform provider development override that points to a locally built `terraform-provider-zillizcloud`.

## Destroy Notes

Before destroying this example, edit `main.tf` and temporarily change the `zillizcloud_byoc_i_project.this` lifecycle protection from `prevent_destroy = true` to `prevent_destroy = false`.

### Keep the GCS Bucket

If you want to keep the GCS bucket and only destroy the other dataplane resources, first remove the bucket resource from this Terraform state:

```bash
terraform state rm 'module.gcs.google_storage_bucket.this[0]'
```

Then run destroy:

```bash
ZILLIZCLOUD_API_KEY=<YourZillizApiKey> \
terraform destroy \
  -var="dataplane_id=<YourZillizDataPlaneId>" \
  -var="project_id=<YourZillizProjectId>" \
  -var="gcp_project_id=<YourGcpProjectId>"
```

After `terraform state rm`, Terraform no longer manages the bucket in this state, so destroy will not try to delete it.

### Delete the GCS Bucket

If you want `terraform destroy` to delete the GCS bucket and all objects in it, `bucket_force_destroy = true` must already be applied to the bucket resource before the destroy plan runs. Apply that bucket setting first:

```bash
ZILLIZCLOUD_API_KEY=<YourZillizApiKey> \
terraform apply \
  -target='module.gcs.google_storage_bucket.this[0]' \
  -var="dataplane_id=<YourZillizDataPlaneId>" \
  -var="project_id=<YourZillizProjectId>" \
  -var="gcp_project_id=<YourGcpProjectId>" \
  -var="bucket_force_destroy=true"
```

Then run destroy with the same required variables:

```bash
ZILLIZCLOUD_API_KEY=<YourZillizApiKey> \
terraform destroy \
  -var="dataplane_id=<YourZillizDataPlaneId>" \
  -var="project_id=<YourZillizProjectId>" \
  -var="gcp_project_id=<YourGcpProjectId>" \
  -var="bucket_force_destroy=true"
```

### PVC StorageClass integration

The shared `enable_pd_kms` / `pd_kms_key_name` configuration described above also
passes the effective key through `ext_config.pd_kms_key_name` to paas-deploy's
`gp3-etcd` PD CSI StorageClass. A bootstrap image containing
https://github.com/zilliztech/paas-deploy/pull/132 is required for this integration.
StorageClass encryption applies to newly provisioned PVC disks; it does not
re-encrypt existing PVCs. Existing dataplane bootstrap updates and PVC disk
migrations remain outside this example's scope. GKE Secrets and GCS use their own
independent CMEK settings.

### GKE-managed Service addresses

For GKE Standard 1.29+, use the GKE-managed Service address range without a subnet secondary range:

```hcl
service_subnet = {
  mode = "gke-managed"
}
```

Do not set `name` or `cidr` in this mode. New subnets only create the Pod secondary range; existing subnets do not require a Service secondary range. An existing cluster must already use GKE-managed Services. This does not migrate an existing cluster's Service range.

Omitting `service_subnet` preserves the current `secondary-range` mode: new subnets create a Service range, and existing subnets require its name. In `gke-managed` mode, `service_subnet_cidr` and the registration's `service_subnet_name` are empty because no subnet secondary range is used; the CIDR output does not describe the cluster's effective managed Service CIDR.

### Discover an existing LB proxy-only subnet

```hcl
lb_subnet_mode = "existing"
# lb_subnet can be omitted.
```

Without `lb_subnet.name`, Terraform discovers the unique `ACTIVE` subnet with purpose `REGIONAL_MANAGED_PROXY` in the selected network project, VPC, and region. This requires `compute.subnetworks.list` in the network project (the host project for Shared VPC). No match or multiple matches fails validation. The discovered name is passed to Zilliz registration.

An explicit `lb_subnet.name` continues to use direct lookup. The default `lb_subnet_mode = "create"` still creates a subnet.

### Disable the LB proxy-only subnet

When the dataplane does not use a regional internal managed load balancer, disable the proxy-only subnet:

```hcl
lb_subnet_mode = "disabled"
```

Do not set `lb_subnet.name` or `lb_subnet.cidr` in this mode. Terraform does not create, read, or discover an LB subnet, and both `lb_subnet_name` and `lb_subnet_cidr` are empty in outputs and Zilliz registration. Omitting `lb_subnet_mode` preserves the backward-compatible default `create` behavior.

### Externally managed GCP APIs

Set `enable_project_services = false` to skip Terraform's automatic GCP API enablement. The backward-compatible default is `true`. Required APIs must already be enabled by the customer when this is disabled, including Cloud KMS and Binary Authorization when those features are configured.

Switching an existing deployment to `false` removes the API resources from Terraform management but does not disable the APIs (`disable_on_destroy = false`).
