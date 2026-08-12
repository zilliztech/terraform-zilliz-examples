# GCP BYOC-I Deployment

This example provisions a GCP BYOC-I dataplane with customer-managed infrastructure and a short-lived GCE VM booter. The Terraform runner does not need network access to the private GKE API server.

## What It Creates

- VPC-native GKE networking, Cloud NAT, and firewall rules
- GCS bucket for dataplane storage
- GKE private regional cluster and node pools from BYOC-I quota settings
- GCP service accounts for GKE nodes, maintenance, storage, and the booter VM
- Optional Private Service Connect endpoint
- Short-lived GCE booter VM that uses a dedicated booter service account to install `cloud-agent` into GKE, then self-deletes after a TTL
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
| `lb_subnet_mode` | `create`, `existing` | Create or read the regional managed proxy subnet |
| `create_cloud_nat` | `true`, `false` | Create dedicated Router/NAT resources, or use existing egress |
| `create_firewall_rules` | `true`, `false` | Create BYOC-I firewall rules, or let the customer manage them |
| `manage_shared_vpc_iam` | `true`, `false` | Manage the GKE service-agent grants in the Shared VPC host project |

Terraform never manages the lifecycle of a VPC or subnet selected with an `existing` mode. Destroy only removes resources that this configuration created.

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

The booter VM always uses a dedicated booter service account. The Zilliz BYOC organization service account is not granted permission to impersonate the maintenance service account. The in-cluster `infra/infra-agent-sa` Kubernetes service account uses GKE Workload Identity to access the maintenance service account instead.

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
terraform state rm module.gcs.google_storage_bucket.this
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
  -target=module.gcs.google_storage_bucket.this \
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
