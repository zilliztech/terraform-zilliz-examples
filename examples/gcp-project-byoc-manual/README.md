# GCP BYOC Manual Deployment

This example demonstrates deploying Zilliz Cloud BYOC on Google Cloud Platform (GCP). It creates VPC, subnets, GCS buckets, GKE cluster resources, and IAM service accounts required for BYOC deployment.

## Overview

The GCP BYOC Manual example provisions:
- VPC network with multiple subnets (primary, pods, services, load balancer)
- Google Cloud Storage (GCS) buckets for Milvus storage
- Google Kubernetes Engine (GKE) cluster configuration
- IAM service accounts (storage, GKE node, cross-account)
- Private Service Connect endpoint (optional)

## Prerequisites

1. **Google Cloud Platform Account**
   - Active GCP project with billing enabled
   - Required APIs enabled (see below)

2. **Terraform CLI** (>= 1.0.0)
   - [Installation Guide](https://developer.hashicorp.com/terraform/downloads)

3. **GCP Credentials** configured
   - Authenticate using: `gcloud auth application-default login`
   - Or set `GOOGLE_APPLICATION_CREDENTIALS` environment variable

4. **Required GCP APIs Enabled**:
   ```bash
   gcloud services enable \
     compute.googleapis.com \
     container.googleapis.com \
     storage-api.googleapis.com \
     iam.googleapis.com \
     servicenetworking.googleapis.com
   ```

5. **Zilliz Cloud Account**
   - Obtain Zilliz service account email for delegation
   - Ensure you have BYOC project creation permissions

## Architecture

This example uses the following Terraform modules:
- [`gcp/vpc`](../../modules/gcp/vpc) - VPC and subnet configuration
- [`gcp/gcs`](../../modules/gcp/gcs) - GCS bucket creation
- [`gcp/iam`](../../modules/gcp/iam) - IAM service accounts
- [`gcp/private-link`](../../modules/gcp/private-link) - Private Service Connect (optional)

## Configuration

### Required Variables

| Variable | Description | Type | Example |
|----------|-------------|------|---------|
| `gcp_project_id` | GCP project ID | `string` | `my-gcp-project` |
| `gcp_region` | GCP region | `string` | `us-west1` |
| `gcp_vpc_cidr` | CIDR block for VPC (x/16) | `string` | `10.0.0.0/16` |
| `zilliz_service_account` | Zilliz service account email for delegation | `string` | `zilliz@...` |

### Optional Variables

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `gcp_zones` | GCP zones for GKE | `list(string)` | `null` (auto-select) |
| `customer_vpc_name` | VPC name | `string` | `zilliz-byoc-vpc` |
| `customer_primary_subnet_name` | Primary subnet name | `string` | `primary-subnet` |
| `customer_primary_subnet_cidr` | Primary subnet CIDR | `string` | `""` |
| `customer_pod_subnet_name` | Pod subnet name | `string` | `""` |
| `customer_pod_subnet_cidr` | Pod subnet CIDR | `string` | `""` |
| `customer_service_subnet_name` | Service subnet name | `string` | `""` |
| `customer_service_subnet_cidr` | Service subnet CIDR | `string` | `""` |
| `customer_lb_subnet_name` | Load balancer subnet name | `string` | `""` |
| `customer_lb_subnet_cidr` | Load balancer subnet CIDR | `string` | `""` |
| `customer_bucket_name` | GCS bucket name | `string` | `""` (auto-generated) |
| `customer_gke_cluster_name` | GKE cluster name | `string` | `""` (auto-generated) |
| `customer_storage_service_account_name` | Storage SA name | `string` | `""` (auto-generated) |
| `customer_cross-account_service_account_name` | Cross-account SA name | `string` | `""` (auto-generated) |
| `customer_gke_node_service_account_name` | GKE node SA name | `string` | `""` (auto-generated) |
| `enable_private_link` | Enable Private Service Connect | `bool` | `true` |

## Deployment Steps

### Step 1: Enable Required APIs

```bash
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  storage-api.googleapis.com \
  iam.googleapis.com \
  servicenetworking.googleapis.com
```

### Step 2: Configure Variables

Edit `terraform.tfvars.json`:

```json
{
  "gcp_project_id": "my-gcp-project",
  "gcp_region": "us-west1",
  "gcp_vpc_cidr": "10.0.0.0/16",
  "zilliz_service_account": "zilliz-service-account@zilliz-project.iam.gserviceaccount.com",
  "enable_private_link": true,
  "customer_vpc_name": "zilliz-byoc-vpc",
  "customer_primary_subnet_name": "primary-subnet",
  "customer_primary_subnet_cidr": "10.0.1.0/24"
}
```

### Step 3: Configure Provider

Edit `provider.tf` to set your GCP project:

```hcl
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
```

### Step 4: Initialize Terraform

```bash
terraform init
```

### Step 5: Review Plan

```bash
terraform plan
```

This will show you all resources that will be created.

### Step 6: Apply Configuration

```bash
terraform apply
```

Review the plan and type `yes` to confirm.

## Outputs

After successful deployment, Terraform outputs a structured configuration:

```json
{
  "1.Google Cloud Platform Project ID": "my-gcp-project",
  "2.Storage Settings": {
    "1.GCS Bucket Name": "zilliz-byoc-vpc-bucket-abc123",
    "2.Service Account Email": "storage-sa@my-gcp-project.iam.gserviceaccount.com"
  },
  "3.GKE Settings": {
    "1.GKE Cluster Name": "zilliz-byoc-vpc-gke",
    "2.GKE Node Service Account Name": "gke-node-sa@my-gcp-project.iam.gserviceaccount.com"
  },
  "4.Cross-Account Settings": {
    "1.Service Account Email": "cross-account-sa@my-gcp-project.iam.gserviceaccount.com"
  },
  "5.VPC Settings": {
    "1.VPC Name": "zilliz-byoc-vpc",
    "2.Primary Subnet Name": "primary-subnet",
    "3.Secondary Subnet Range Name(Pods)": "pods-subnet-range",
    "4.Secondary Subnet Range Name(Services)": "services-subnet-range",
    "5.Load Balance Subnet Name": "lb-subnet",
    "6.Private Service Connect": "10.x.x.x"
  }
}
```

## Resource Details

### Created Resources

1. **VPC Network**:
   - VPC with specified CIDR block
   - Primary subnet for nodes
   - Secondary subnet ranges for pods and services
   - Load balancer subnet

2. **GCS Bucket**:
   - Bucket for Milvus storage
   - Auto-generated name if not specified: `{vpc_name}-bucket-{random_id}`

3. **IAM Service Accounts**:
   - Storage service account (for GCS access)
   - GKE node service account (for node operations)
   - Cross-account service account (for Zilliz management)
   - Service account delegation configured

4. **Private Service Connect** (if enabled):
   - Private endpoint for secure connectivity

### Resource Naming

- **VPC**: Uses `customer_vpc_name` variable
- **Buckets**: `{vpc_name}-bucket-{random_id}` or `customer_bucket_name`
- **Service Accounts**: `{vpc_name}-{type}-sa` or custom names
- **GKE Cluster**: `{vpc_name}-gke` or `customer_gke_cluster_name`

## Subnet Configuration

The example creates multiple subnet types:

1. **Primary Subnet**: For GKE nodes
   - Name: `customer_primary_subnet_name`
   - CIDR: `customer_primary_subnet_cidr`

2. **Pod Subnet**: Secondary range for Kubernetes pods
   - Name: `customer_pod_subnet_name`
   - CIDR: `customer_pod_subnet_cidr`

3. **Service Subnet**: Secondary range for Kubernetes services
   - Name: `customer_service_subnet_name`
   - CIDR: `customer_service_subnet_cidr`

4. **Load Balancer Subnet**: For load balancer resources
   - Name: `customer_lb_subnet_name`
   - CIDR: `customer_lb_subnet_cidr`

## Private Service Connect

Private Service Connect provides secure, private connectivity to Zilliz Cloud services without traversing the public internet.

To enable:
```json
{
  "enable_private_link": true
}
```

The endpoint IP will be available in the outputs under `"5.VPC Settings"."6.Private Service Connect"`.

## Service Account Delegation

This example configures service account delegation, allowing Zilliz's service account to impersonate your service accounts. This is configured via the `zilliz_service_account` variable.

**Security Note**: Ensure you trust the Zilliz service account email provided.

## High Availability

For high availability:
- Deploy across multiple GCP zones
- Use regional persistent disks
- Configure GKE cluster with multiple node pools
- Enable GKE autoscaling

## Security Considerations

1. **Service Account Permissions**: Follows least privilege principle
2. **VPC**: Isolated network environment
3. **GCS Bucket**: Private bucket with IAM-based access control
4. **Private Service Connect**: Encrypted, private connectivity

## Troubleshooting

### Common Issues

**Error: "API not enabled"**
- Enable required APIs (see Prerequisites)
- Wait a few minutes after enabling APIs

**Error: "Permission denied"**
- Verify your GCP credentials have necessary permissions
- Check IAM roles: `roles/compute.admin`, `roles/container.admin`, `roles/storage.admin`, `roles/iam.serviceAccountAdmin`

**Error: "Bucket name already exists"**
- GCS bucket names must be globally unique
- Use `customer_bucket_name` to specify a unique name

**Error: "VPC CIDR conflict"**
- Ensure VPC CIDR doesn't overlap with existing networks
- Use a unique CIDR block

### Verification

Verify resources in GCP Console:
- VPC: VPC Network → VPC networks
- GCS: Cloud Storage → Buckets
- IAM: IAM & Admin → Service Accounts
- GKE: Kubernetes Engine → Clusters

## Cleanup

To destroy all created resources:

```bash
terraform destroy
```

**Note**: Ensure no other resources depend on the created VPC, GCS bucket, or service accounts before destroying.

## Best Practices

1. **Resource Naming**: Use descriptive, consistent naming conventions
2. **CIDR Planning**: Plan subnet CIDRs to avoid conflicts
3. **Service Accounts**: Regularly review service account permissions
4. **Cost Management**: Set up billing alerts and budgets
5. **Monitoring**: Enable Cloud Monitoring for GKE clusters
6. **Backup**: Implement backup strategies for GCS buckets

## Related Documentation

- [GCP VPC Documentation](https://cloud.google.com/vpc/docs)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [GCS Documentation](https://cloud.google.com/storage/docs)
- [Zilliz Cloud Documentation](https://docs.zilliz.com/)

