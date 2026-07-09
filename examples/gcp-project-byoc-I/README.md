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
- A GCP project with the APIs needed for Artifact Registry, Compute Engine, GKE, IAM, Service Usage, and Cloud Storage
- By default, the Terraform runner needs `roles/resourcemanager.tagAdmin` and `roles/resourcemanager.tagUser` to create and bind Resource Manager tags
- For Private Service Connect, `gcp_psc_service_attachment_id` is optional. When unset, it defaults to `projects/vdc-dev-test/regions/<region>/serviceAttachments/zilliz-byoc-psc` for `env = "UAT"` and `projects/vdc-prod/regions/<region>/serviceAttachments/zilliz-byoc-psc-service` otherwise.

## Usage

```bash
cp terraform.sample.tfvars terraform.tfvars
terraform init
terraform plan
terraform apply
```

The booter VM receives the BYOC-I agent token through Terraform-managed VM metadata. This is intentional for v1 and means the token is visible in Terraform state and VM metadata.

The GCP region is read from `zillizcloud_byoc_i_project_settings`. Set `gcp_project_id` in `terraform.tfvars`.

The PSC service attachment ID can be overridden with `gcp_psc_service_attachment_id`. When it is not set, Terraform builds the ID from the current BYOC-I project region and environment.

The example grants the storage service account to the fixed BYOC-I Kubernetes service accounts used by Loki and Milvus bootstrap through GKE Workload Identity. It also grants storage Workload Identity access to the target GKE cluster because instance namespaces and service accounts are created at runtime.

The booter VM always uses a dedicated booter service account. The Zilliz BYOC organization service account is not granted permission to impersonate the maintenance service account. The in-cluster `infra/infra-agent-sa` Kubernetes service account uses GKE Workload Identity to access the maintenance service account instead.

The booter image is not required in `terraform.tfvars`. Production defaults to `gcr.io/zilliz-byoc-prod/gcp-byoc-i-booter:latest`; UAT defaults to `gcr.io/zilliz-byoc-uat/gcp-byoc-i-booter:latest`. For development testing only, override `booter_image` locally.

Resource Manager tags are enabled by default. When no tag IDs are provided, Terraform creates a per-dataplane tag key derived from `data_plane_id` and a `booter` tag value, so multiple BYOC-I dataplanes can be created in the same GCP project without sharing a fixed project-level tag key. If your Terraform runner cannot manage tags, either set both `vendor_tag_key_id` and `vendor_tag_value_id` to use a pre-created tag, or set `enable_resource_manager_tags = false`. With tags enabled, booter self-delete permission is scoped to the exact booter VM instance name plus the Resource Manager tag. When tags are disabled, booter self-delete permission is scoped to the exact booter VM instance name only.

When Private Service Connect is enabled, the example still bootstraps `cloud-agent` through the public regional tunnel host by default, then reports the PSC endpoint IP in `zillizcloud_byoc_i_project`. This avoids blocking first connect while the PSC endpoint is still pending producer acceptance. To force agent bootstrap through PSC, set `agent_server_host` to the `.byoc.` tunnel host.

If the provider version has not been released yet, use a local Terraform provider development override that points to a locally built `terraform-provider-zillizcloud`.

## Destroy Notes

Before destroying this example, edit `main.tf` and temporarily change the `zillizcloud_byoc_i_project.this` lifecycle protection from `prevent_destroy = true` to `prevent_destroy = false`.

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

If you do not want Terraform to delete the GCS bucket, do not rely only on `bucket_force_destroy = false`: Terraform can still delete an empty bucket during destroy. Remove the bucket from Terraform state before running destroy, or move its state to another Terraform workspace/configuration that will continue to manage it:

```bash
terraform state rm module.gcs.google_storage_bucket.this
```

After the bucket is removed from this state, run `terraform destroy` with `bucket_force_destroy = false` or omit the variable and use the default value.
