# AWS BYOC Standard Deployment

This example demonstrates a fully automated deployment of Zilliz Cloud BYOC on AWS. It creates all required AWS resources including VPC, subnets, security groups, S3 buckets, IAM roles, and the Zilliz Cloud BYOC project resource.

## Overview

The AWS BYOC Standard example provides a complete, automated deployment that:
- Creates a new VPC with subnets across multiple availability zones
- Provisions S3 buckets for Milvus storage
- Sets up IAM roles and policies (cross-account, EKS, storage)
- Creates security groups with appropriate rules
- Optionally configures VPC PrivateLink endpoints
- Provisions the Zilliz Cloud BYOC project with instance configurations

## Prerequisites

1. **AWS Account** with appropriate permissions
   - See [AWS Requirements](../AWS Requirements.md) for detailed requirements
   - Basic IAM permissions to create VPC, S3, IAM resources

2. **Terraform CLI** (>= 1.0.0)
   - [Installation Guide](https://developer.hashicorp.com/terraform/downloads)

3. **AWS Credentials** configured
   - Configure using [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
   - Or set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables

4. **Zilliz Cloud Account**
   - Obtain API key from Zilliz Cloud console
   - Ensure you have BYOC project creation permissions

## Architecture

This example uses the following Terraform modules:
- [`aws_byoc/aws_bucket`](../../modules/aws_byoc/aws_bucket) - S3 bucket creation
- [`aws_byoc/aws_iam`](../../modules/aws_byoc/aws_iam) - IAM roles and policies
- [`aws_byoc/aws_vpc`](../../modules/aws_byoc/aws_vpc) - VPC and networking

## Configuration

### Required Variables

| Variable | Description | Type | Example |
|----------|-------------|------|---------|
| `region` | AWS region for deployment | `string` | `us-west-2` |
| `vpc_cidr` | CIDR block for the VPC | `string` | `10.0.0.0/16` |
| `name` | Name of the BYOC project | `string` | `my-byoc-project` |

### Optional Variables

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `enable_private_link` | Enable VPC PrivateLink | `bool` | `false` |
| `instances` | Instance configuration | `object` | See below |

### Instance Configuration

The `instances` variable allows you to configure Milvus cluster instances:

```hcl
instances = {
  core = {
    vm    = "m6i.2xlarge"
    count = 3
  }
  fundamental = {
    vm        = "m6i.2xlarge"
    min_count = 1
    max_count = 2
  }
  search = {
    vm        = "m6id.4xlarge"
    min_count = 1
    max_count = 2
  }
  index = {
    vm        = "m6i.2xlarge"
    min_count = 1
    max_count = 2
  }
  auto_scaling = true
  arch         = "X86"
}
```

**Instance Types**:
- `core`: Core Milvus components (fixed count)
- `fundamental`: Fundamental components (auto-scaling)
- `search`: Search nodes (auto-scaling)
- `index`: Index nodes (auto-scaling)

**Architecture**: `X86` or `ARM`

## Deployment Steps

### Step 1: Configure Variables

Copy and edit `terraform.tfvars.json`:

```json
{
  "region": "us-west-2",
  "vpc_cidr": "10.0.0.0/16",
  "name": "my-byoc-project",
  "enable_private_link": false,
  "instances": {
    "core": {
      "vm": "m6i.2xlarge",
      "count": 3
    },
    "fundamental": {
      "vm": "m6i.2xlarge",
      "min_count": 1,
      "max_count": 2
    },
    "search": {
      "vm": "m6id.4xlarge",
      "min_count": 1,
      "max_count": 2
    },
    "index": {
      "vm": "m6i.2xlarge",
      "min_count": 1,
      "max_count": 2
    },
    "auto_scaling": true,
    "arch": "X86"
  }
}
```

### Step 2: Configure Provider

Edit `provider.tf` to set your Zilliz Cloud API key:

```hcl
provider "zillizcloud" {
  api_key = "your-api-key-here"
}
```

### Step 3: Initialize Terraform

```bash
terraform init
```

### Step 4: Review Plan

```bash
terraform plan
```

This will show you all resources that will be created.

### Step 5: Apply Configuration

```bash
terraform apply
```

Review the plan and type `yes` to confirm.

## Outputs

After successful deployment, Terraform will output:

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC ID |
| `subnet_id` | List of subnet IDs |
| `security_group_id` | Security group ID |
| `bucket_name` | S3 bucket name |
| `cross_account_role_arn` | Cross-account IAM role ARN |
| `eks_role_arn` | EKS IAM role ARN |
| `storage_role_arn` | Storage IAM role ARN |
| `external_id` | External ID for role assumption |
| `project_id` | Zilliz Cloud BYOC project ID |

Example output:
```
vpc_id = "vpc-xxxxxxxxxxxx"
subnet_id = [
  "subnet-xxxxxxxxxxxx",
  "subnet-xxxxxxxxxxxx",
  "subnet-xxxxxxxxxxxx",
]
security_group_id = "sg-xxxxxxxxxxxx"
bucket_name = "byoc-name-milvus"
cross_account_role_arn = "arn:aws:iam::xxxxxxxxxxxx:role/zilliz-byoc-byoc-name-cross-account-role"
eks_role_arn = "arn:aws:iam::xxxxxxxxxxxx:role/zilliz-byoc-byoc-name-eks-role"
storage_role_arn = "arn:aws:iam::xxxxxxxxxxxx:role/zilliz-byoc-byoc-name-storage-role"
external_id = "externalId from zilliz"
project_id = "project-xxxxxxxxxxxx"
```

## Resource Details

### Created Resources

This example creates:

1. **VPC Resources**:
   - VPC with specified CIDR block
   - Public and private subnets across multiple AZs
   - Internet Gateway
   - NAT Gateway (for private subnets)
   - Route tables
   - Security groups

2. **S3 Resources**:
   - S3 bucket for Milvus storage (`{name}-milvus`)

3. **IAM Resources**:
   - Cross-account role for Zilliz management
   - EKS role for cluster operations
   - Storage role for S3 access

4. **Zilliz Cloud Resources**:
   - BYOC project resource
   - Instance configurations

### Resource Naming

Resources are named with the pattern: `zilliz-byoc-{name}-{resource-type}`

Example: `zilliz-byoc-my-project-cross-account-role`

## PrivateLink Support

To enable VPC PrivateLink, set `enable_private_link = true`:

```json
{
  "enable_private_link": true
}
```

This will create a VPC endpoint for secure, private connectivity to Zilliz Cloud services.

## High Availability

The example creates resources across multiple availability zones (typically 3) to ensure high availability. See [AWS Requirements.md](../AWS Requirements.md) for detailed HA configuration.

## Security Considerations

1. **IAM Roles**: Follows least privilege principle
2. **Security Groups**: Configured to allow necessary traffic only
3. **S3 Bucket**: Private bucket with appropriate access controls
4. **VPC**: Isolated network environment

## Troubleshooting

### Common Issues

**Error: "AccessDenied"**
- Ensure your AWS credentials have sufficient permissions
- Check IAM policies for required actions

**Error: "BucketAlreadyExists"**
- S3 bucket names must be globally unique
- Change the `name` variable to use a unique bucket name

**Error: "InvalidParameterValue"**
- Verify VPC CIDR doesn't overlap with existing networks
- Check instance types are available in your region

### Verification

Verify resources in AWS Console:
- VPC: EC2 → VPCs
- S3: S3 → Buckets
- IAM: IAM → Roles
- Zilliz: Zilliz Cloud Console → Projects

## Cleanup

To destroy all created resources:

```bash
terraform destroy
```

**Note**: The `zillizcloud_byoc_project` resource has `prevent_destroy = true` in its lifecycle block. You may need to remove this or manually delete the project in the Zilliz Cloud console first.

## Next Steps

After deployment:
1. Verify the project in Zilliz Cloud console
2. Configure your application to use the BYOC project
3. Set up monitoring and alerting
4. Review security configurations
5. Plan for backup and disaster recovery

## Related Documentation

- [AWS Requirements](../AWS Requirements.md)
- [AWS BYOC-I Example](../aws-project-byoc-I/README.md) - For customer-managed VPC
- [AWS BYOC Manual Example](../aws-project-byoc-manual/README.md) - For existing infrastructure
- [Zilliz Cloud Documentation](https://docs.zilliz.com/)

