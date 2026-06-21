# GCP BYOC-I Deployment

This example provisions a GCP BYOC-I dataplane with customer-managed infrastructure and a short-lived GCE VM booter. The Terraform runner does not need network access to the private GKE API server.

## What It Creates

- VPC-native GKE networking, Cloud NAT, and firewall rules
- GCS bucket for dataplane storage
- GKE private regional cluster and node pools from BYOC-I quota settings
- GCP service accounts for GKE nodes, maintenance, storage, and the booter VM
- Optional Private Service Connect endpoint
- GCE booter VM that installs `cloud-agent` into GKE and stops itself on success
- `zillizcloud_byoc_i_project_agent` and `zillizcloud_byoc_i_project`

## Requirements

- Terraform `>= 1.6.0`
- Google provider `~> 6.32.0`
- Zilliz Cloud provider version that includes `zillizcloud_byoc_i_project.gcp`
- A GCP project with the APIs needed for Compute Engine, GKE, IAM, Service Usage, and Cloud Storage
- For Private Service Connect, set `gcp_psc_service_attachment_id` or add the region entry in `modules/conf.yaml`

## Usage

```bash
cp terraform.sample.tfvars terraform.tfvars
terraform init
terraform plan
terraform apply
```

The booter VM receives the BYOC-I agent token through Terraform-managed VM metadata. This is intentional for v1 and means the token is visible in Terraform state and VM metadata.

The GCP region is read from `zillizcloud_byoc_i_project_settings`. Set only `gcp_project_id` in `terraform.tfvars`.

The booter image defaults to the public `gcr.io/zilliz-public/gcp-byoc-i-booter:latest` image and is not required in `terraform.tfvars`. For development testing only, override `booter_image` locally.

If the provider version has not been released yet, use a local Terraform provider development override that points to a locally built `terraform-provider-zillizcloud`.
