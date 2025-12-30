# AWS BYOC-I Deployment Guide

This example demonstrates deploying Zilliz Cloud BYOC-I on AWS with customer-managed VPC. It automatically creates all required AWS resources for a complete BYOC-I deployment while providing extensive customization options for enterprise requirements.

## Overview

This example uses the following Terraform modules:
- [`aws_byoc_i/eks`](../../modules/aws_byoc_i/eks) - EKS cluster and node group management
- [`aws_byoc_i/privatelink`](../../modules/aws_byoc_i/privatelink) - VPC PrivateLink endpoint configuration
- [`aws_byoc_i/s3`](../../modules/aws_byoc_i/s3) - S3 bucket management
- [`aws_byoc_i/vpc`](../../modules/aws_byoc_i/vpc) - VPC and endpoint configuration (optional)

**Terraform Provider**: [zilliz-cloud provider](https://registry.terraform.io/providers/zilliztech/zillizcloud/latest)

## Features by Function

### 1. S3 Storage Bucket

#### Default
- **Automatically Created**: Yes, always created
- **Purpose**: Stores Milvus data, backups, and operational logs
- **Default Name**: `{dataplane_id}-milvus`
  - Example: If `dataplane_id = "dp-abc123"`, bucket name is `dp-abc123-milvus`
- **Configuration**:
  - Private bucket with appropriate access controls
  - Versioning and encryption ready
  - Tagged with default Zilliz tags

#### Custom
- **Custom Bucket Name**: Override the default naming
  ```hcl
  customer_bucket_name = "my-company-milvus-storage"
  ```
  - **Note**: S3 bucket names must be globally unique across all AWS accounts
- **Custom Tags**: Add additional tags (see Tags section)

---

### 2. EKS Cluster and Node Groups

#### Default
- **EKS Cluster**:
  - Automatically created with required configuration
  - Default name: `{dataplane_id}`
  - Configured with required add-ons (AWS Load Balancer Controller, EBS CSI driver, etc.)
  - Supports private API endpoint
  - Node groups created based on Zilliz Cloud project settings

- **Node Groups** (automatically created based on project configuration):
  - **Core nodes**: Fixed count nodes for core Milvus components
  - **Fundamental nodes**: Auto-scaling nodes for fundamental services
  - **Search nodes**: Auto-scaling nodes for search operations
  - **Index nodes**: Auto-scaling nodes for index operations
  - **Init nodes**: Initialization nodes (if required)

- **Subnet Configuration**:
  - Uses `customer_private_subnet_ids` for worker nodes
  - Uses `customer_eks_control_plane_private_subnet_ids` if provided, otherwise uses `customer_private_subnet_ids`
  - EKS control plane subnets must span at least 2 availability zones

#### Custom
- **Custom Cluster Name**:
  ```hcl
  customer_eks_cluster_name = "my-company-eks-cluster"
  ```

- **Custom Pod Subnets**: Specify dedicated subnets for Kubernetes pods
  ```hcl
  customer_pod_subnet_ids = ["subnet-444", "subnet-555"]
  ```

- **Custom EKS Control Plane Subnets**: Use separate subnets for EKS API server
  ```hcl
  customer_eks_control_plane_private_subnet_ids = ["subnet-111", "subnet-222"]
  ```
  - **Requirement**: Must span at least 2 availability zones

- **Custom Node Security Groups**:
  ```hcl
  customer_node_security_group_ids = ["sg-999"]
  ```

- **Minimal Roles**: Enable role separation (see IAM Roles section)

---

### 3. IAM Roles

#### Default
The example automatically creates **4 IAM roles** with specific purposes:

1. **EKS Cluster Role**
   - Default name: `{dataplane_id}-eks-role`
   - Purpose: Manages EKS cluster operations
   - Permissions: EKS cluster management, VPC resource controller

2. **EKS Add-on Role**
   - Default name: `{dataplane_id}-addon-role`
   - Purpose: Enables EKS add-ons (Load Balancer Controller, EBS CSI, etc.)
   - Permissions: AWS service integration for add-ons

3. **Storage Role**
   - Default name: `{dataplane_id}-storage-role`
   - Purpose: Manages S3 bucket access for Milvus
   - Permissions: S3 read/write operations

4. **Maintenance Role**
   - Default name: `{dataplane_id}-maintenance-role`
   - Purpose: Cluster administration and maintenance
   - Permissions: Cross-account access for Zilliz management

**Default Behavior**: All roles use unified role architecture (cluster and nodes share the same role)

#### Custom
- **Custom Role Names**: Override default naming for any role
  ```hcl
  customer_eks_role_name          = "my-company-eks-role"
  customer_eks_addon_role_name    = "my-company-addon-role"
  customer_storage_role_name      = "my-company-storage-role"
  customer_maintenance_role_name  = "my-company-maintenance-role"
  ```

- **Minimal Roles (Advanced)**: Enable role separation for enhanced security
  ```hcl
  minimal_roles = {
    enabled = true
    cluster_role = {
      name = "my-company-eks-cluster-role"
    }
    node_role = {
      name = "my-company-eks-node-role"
    }
  }
  ```
  
  **Use Existing Roles**:
  ```hcl
  minimal_roles = {
    enabled = true
    cluster_role = {
      use_existing_arn = "arn:aws:iam::123456789012:role/my-existing-cluster-role"
    }
    node_role = {
      use_existing_arn = "arn:aws:iam::123456789012:role/my-existing-node-role"
    }
  }
  ```
  
  See [Minimal Roles Documentation](../../modules/aws_byoc_i/eks/README_minimal_roles.md) for detailed information.

---

### 4. Network/VPC Configuration

#### Default
- **VPC Selection Logic**:
  - If `customer_vpc_id` is provided: Uses your existing VPC
  - If `customer_vpc_id` is empty: Creates a new VPC automatically

- **When Using Existing VPC** (recommended):
  - Uses your provided VPC, security groups, and subnets
  - No additional VPC resources created

- **When Creating New VPC**:
  - Creates VPC with specified CIDR block (`vpc_cidr`, default: `10.0.0.0/16`)
  - Creates public and private subnets across multiple availability zones
  - Creates Internet Gateway and NAT Gateway
  - Creates route tables and security groups
  - Optionally creates VPC endpoints for AWS services (if `enable_endpoint = true`)

- **Default Subnet Usage**:
  - Worker nodes: `customer_private_subnet_ids`
  - EKS control plane: `customer_eks_control_plane_private_subnet_ids` (if provided) or `customer_private_subnet_ids`
  - PrivateLink: `customer_private_link_subnet_ids` (if provided) or `customer_private_subnet_ids`

#### Custom
- **Use Existing VPC** (recommended):
  ```hcl
  customer_vpc_id               = "vpc-12345678"
  customer_security_group_id    = "sg-12345678"
  customer_private_subnet_ids   = ["subnet-111", "subnet-222", "subnet-333"]
  ```

- **Create New VPC**:
  ```hcl
  customer_vpc_id = ""  # Leave empty to create new VPC
  vpc_cidr        = "10.0.0.0/16"
  enable_endpoint = true  # Enable VPC endpoints for AWS services
  ```

- **Custom PrivateLink Subnets**: Use different subnets for PrivateLink endpoints
  ```hcl
  customer_private_link_subnet_ids = ["subnet-111", "subnet-222"]
  ```

- **Custom PrivateLink Security Groups**:
  ```hcl
  customer_private_link_security_group_ids = ["sg-888"]
  ```

- **Create PrivateLink Security Group**:
  ```hcl
  create_private_link_security_group = true
  private_link_security_group_name   = "my-privatelink-sg"
  ```

---

### 5. VPC PrivateLink Endpoint

#### Default
- **When Created**: Automatically created if PrivateLink is enabled in Zilliz Cloud project settings
- **Configuration**:
  - Private hosted zone automatically configured (unless `enable_manual_private_link = true`)
  - Uses default subnets: `customer_private_link_subnet_ids` or `customer_private_subnet_ids`
  - Uses default security groups: `customer_private_link_security_group_ids` or VPC default security group
- **Purpose**: Provides secure, private connectivity to Zilliz Cloud services without traversing the public internet

#### Custom
- **Manual PrivateLink Configuration**: Disable automatic hosted zone creation
  ```hcl
  enable_manual_private_link = true
  ```

- **Custom PrivateLink Subnets**: Specify dedicated subnets
  ```hcl
  customer_private_link_subnet_ids = ["subnet-111", "subnet-222"]
  ```

- **Custom PrivateLink Security Groups**:
  ```hcl
  customer_private_link_security_group_ids = ["sg-888"]
  ```

- **Create Custom PrivateLink Security Group**:
  ```hcl
  create_private_link_security_group = true
  private_link_security_group_name   = "my-privatelink-sg"
  ```

---

### 6. ECR Integration

#### Default
- **Default ECR Configuration**:
  ```hcl
  customer_ecr = {
    ecr_account_id = "965570967084"  # Zilliz default account
    ecr_region     = ""                # Uses project region
    ecr_prefix     = "zilliz-byoc"     # Default prefix
  }
  ```
- **Behavior**: Uses Zilliz's default ECR repositories

#### Custom
- **Use Your Own ECR**: Integrate with existing ECR repositories
  ```hcl
  customer_ecr = {
    ecr_account_id = "123456789012"  # Your AWS account ID
    ecr_region     = "us-west-2"      # Your ECR region
    ecr_prefix     = "my-company"     # Your repository prefix
  }
  ```

- **Booter Configuration** (Advanced): Customize container image management
  ```hcl
  booter = {
    account_id = "123456789012"
    region     = "us-west-2"
    prefix     = "my-company"
    image      = "my-custom-image"
  }
  ```

---

### 7. Resource Tagging

#### Default
- **Default Tags**: Resources are automatically tagged with:
  - `Vendor = "zilliz-byoc"` (applied to all resources)
  - Resource-specific tags as required

#### Custom
- **Add Custom Tags**: Apply custom tags to all resources
  ```hcl
  custom_tags = {
    Environment = "production"
    Team        = "data-platform"
    Project     = "milvus-byoc"
    CostCenter  = "engineering"
    Owner       = "data-team"
  }
  ```

- **Tags Applied To**:
  - EKS cluster and all node groups
  - S3 bucket
  - All IAM roles
  - PrivateLink endpoints
  - VPC resources (if created)

---

## Configuration Reference

### Required Variables

| Variable | Description | Type | Example |
|----------|-------------|------|---------|
| `project_id` | Zilliz Cloud project ID | `string` | `proj-123456` |
| `dataplane_id` | Zilliz Cloud data plane ID | `string` | `dp-123456` |
| `customer_vpc_id` | Your existing VPC ID (or `""` to create new) | `string` | `vpc-12345678` or `""` |
| `customer_security_group_id` | Security group ID (required if using existing VPC) | `string` | `sg-12345678` |
| `customer_private_subnet_ids` | Private subnet IDs (required if using existing VPC) | `list(string)` | `["subnet-111", "subnet-222"]` |

### Optional Variables

#### Network
```hcl
vpc_cidr                                    = "10.0.0.0/16"
customer_eks_control_plane_private_subnet_ids = ["subnet-111", "subnet-222"]
customer_private_link_subnet_ids            = ["subnet-111", "subnet-222"]
customer_pod_subnet_ids                     = ["subnet-444", "subnet-555"]
customer_node_security_group_ids            = ["sg-999"]
customer_private_link_security_group_ids    = ["sg-888"]
create_private_link_security_group          = true
private_link_security_group_name            = "my-privatelink-sg"
enable_endpoint                             = true
```

#### Resource Naming
```hcl
customer_bucket_name            = "my-custom-bucket"
customer_eks_cluster_name       = "my-custom-eks-cluster"
customer_storage_role_name      = "my-custom-storage-role"
customer_eks_addon_role_name    = "my-custom-addon-role"
customer_eks_role_name          = "my-custom-eks-role"
customer_maintenance_role_name  = "my-custom-maintenance-role"
```

#### ECR
```hcl
customer_ecr = {
  ecr_account_id = "123456789012"
  ecr_region     = "us-west-2"
  ecr_prefix     = "my-company"
}
```

#### Tags
```hcl
custom_tags = {
  Environment = "production"
  Team        = "data-platform"
}
```

#### Advanced
```hcl
enable_manual_private_link = false
booter = {
  account_id = ""
  region     = ""
  prefix     = ""
  image      = ""
}
minimal_roles = {
  enabled = false
  cluster_role = {}
  node_role = {}
}
```

## Prerequisites

1. **BYOC-I Organization**: Ensure you are the owner of a BYOC-I organization in Zilliz Cloud

2. **AWS Account**:
   - If using existing VPC: VPC with subnets across at least 2 availability zones
   - Required IAM permissions (see [IAM Permissions Guide](./terraform-permissions/README.md))

3. **Terraform CLI** (>= 1.0.0):
   - [Installation Guide](https://developer.hashicorp.com/terraform/downloads)

4. **AWS Credentials** configured:
   - [AWS CLI Configuration Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)

5. **Zilliz Cloud API Key**:
   - Obtain from Zilliz Cloud console → Organization → API Keys

## Deployment Steps

### Step 1: Prepare Deployment Environment

1. **Configure AWS Credentials**:
   ```bash
   aws configure
   # Or set environment variables:
   export AWS_ACCESS_KEY_ID=your-access-key
   export AWS_SECRET_ACCESS_KEY=your-secret-key
   ```

2. **Install Terraform**:
   ```bash
   # Follow: https://developer.hashicorp.com/terraform/install
   ```

3. **Configure Zilliz Cloud Provider**:
   
   Edit `provider.tf`:
   ```hcl
   provider "zillizcloud" {
     api_key = "your-zilliz-api-key"
   }
   ```

### Step 2: Configure Variables

1. **Copy sample variables file**:
   ```bash
   cp terraform.sample.tfvars terraform.tfvars
   ```

2. **Edit `terraform.tfvars`** with your values:

   **Minimal Configuration (Using Existing VPC)**:
   ```hcl
   project_id                  = "your-project-id"
   dataplane_id                = "your-dataplane-id"
   customer_vpc_id             = "vpc-12345678"
   customer_security_group_id  = "sg-12345678"
   customer_private_subnet_ids = ["subnet-111", "subnet-222", "subnet-333"]
   ```

   **With Customizations**:
   ```hcl
   project_id                  = "your-project-id"
   dataplane_id                = "your-dataplane-id"
   customer_vpc_id             = "vpc-12345678"
   customer_security_group_id  = "sg-12345678"
   customer_private_subnet_ids = ["subnet-111", "subnet-222", "subnet-333"]
   
   # Custom resource names
   customer_bucket_name        = "my-company-milvus-storage"
   customer_eks_cluster_name   = "my-company-eks-cluster"
   
   # Custom tags
   custom_tags = {
     Environment = "production"
     Team        = "data-platform"
   }
   ```

### Step 3: Deploy Infrastructure

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Review Plan**:
   ```bash
   terraform plan
   ```
   
   This shows all resources that will be created.

3. **Apply Configuration**:
   ```bash
   terraform apply
   ```
   
   Review the plan and type `yes` to confirm.

### Step 4: Verify Deployment

After deployment completes, verify resources:

1. **Check Terraform Outputs**:
   ```bash
   terraform output
   ```

2. **Verify in AWS Console**:
   - **EKS**: AWS Console → EKS → Clusters
   - **S3**: AWS Console → S3 → Buckets
   - **IAM**: AWS Console → IAM → Roles
   - **VPC**: AWS Console → VPC → Endpoints (if PrivateLink enabled)

3. **Verify in Zilliz Cloud Console**:
   - Check project status
   - Verify data plane connectivity

## Outputs

After successful deployment:

| Output | Description |
|--------|-------------|
| `data_plane_id` | BYOC project data plane ID |
| `project_id` | BYOC project ID |

## Important Notes

### AWS Service-Linked Roles

When creating EKS clusters and node groups, ensure these AWS service-linked roles exist:

- `AWSServiceRoleForAmazonEKS` (`eks.amazonaws.com`)
- `AWSServiceRoleForAmazonEKSNodegroup` (`eks-nodegroup.amazonaws.com`)

**Create if missing**:
```bash
aws iam create-service-linked-role --aws-service-name eks.amazonaws.com
aws iam create-service-linked-role --aws-service-name eks-nodegroup.amazonaws.com
```

These roles are typically created automatically by AWS when using the AWS Console, but may need manual creation when using Terraform.

**Reference**: [AWS EKS Service-Linked Roles Documentation](https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html)

### IAM Permissions

Ensure your AWS credentials have the required permissions. See [IAM Permissions Guide](./terraform-permissions/README.md) for detailed policy requirements.

### High Availability

- Deploy across at least 3 availability zones for high availability
- EKS control plane subnets must span at least 2 availability zones
- See [AWS Requirements](../AWS Requirements.md) for detailed HA configuration

### VPC Requirements

When using existing VPC:
- Subnets must be in at least 2 different availability zones
- Security groups must allow necessary traffic
- PrivateLink subnets must allow agent pods to access the endpoint

When creating new VPC:
- VPC module automatically creates resources across multiple AZs
- Security groups are configured with appropriate rules
- VPC endpoints are created if `enable_endpoint = true`

## Related Documentation

- [IAM Permissions Guide](./terraform-permissions/README.md)
- [AWS Requirements](../AWS-Requirements.md)
- [Minimal Roles Documentation](../../modules/aws_byoc_i/eks/README_minimal_roles.md)
- [Zilliz Cloud Documentation](https://docs.zilliz.com/)
