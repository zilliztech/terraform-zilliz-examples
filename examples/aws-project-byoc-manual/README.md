# AWS BYOC Manual Deployment

This example demonstrates deploying Zilliz Cloud BYOC on AWS using your existing infrastructure. Unlike the standard deployment, this example creates minimal resources and integrates with your existing VPC, subnets, and security groups.

## Overview

The AWS BYOC Manual example is designed for production environments where you:
- Already have VPC and networking infrastructure
- Want to reuse existing security groups
- Need to integrate with existing IAM roles
- Require compliance with existing infrastructure standards

This example creates:
- S3 buckets for Milvus storage
- IAM roles and policies (if not using existing)
- Outputs for integration with Zilliz Cloud console

## Prerequisites

1. **Existing AWS Infrastructure**:
   - VPC with subnets
   - Security groups
   - Internet connectivity (NAT Gateway or Internet Gateway)

2. **AWS Account** with appropriate permissions
   - Permissions to create S3 buckets and IAM roles
   - Access to existing VPC resources

3. **Terraform CLI** (>= 1.0.0)
   - [Installation Guide](https://developer.hashicorp.com/terraform/downloads)

4. **AWS Credentials** configured
   - Configure using [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)

5. **Zilliz Cloud Account**
   - Obtain External ID from Zilliz Cloud console
   - Ensure you have BYOC project creation permissions

## Architecture

This example uses the following Terraform modules:
- [`aws_byoc/aws_bucket`](../../modules/aws_byoc/aws_bucket) - S3 bucket creation
- [`aws_byoc/aws_iam`](../../modules/aws_byoc/aws_iam) - IAM roles and policies
- [`aws_byoc/aws_vpc`](../../modules/aws_byoc/aws_vpc) - VPC resources (optional, if creating new VPC)

**Note**: This example can work with existing VPC resources or create new ones based on your configuration.

## Configuration

### Required Variables

| Variable | Description | Type | Example |
|----------|-------------|------|---------|
| `region` | AWS region for deployment | `string` | `us-west-2` |
| `vpc_cidr` | CIDR block for the VPC (if creating new) | `string` | `10.0.0.0/16` |
| `name` | Name of the BYOC project | `string` | `my-byoc-project` |
| `ExternalId` | External ID from Zilliz Cloud console | `string` | `abc123...` |

### Optional Variables

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `enable_private_link` | Enable VPC PrivateLink | `bool` | `false` |

## Deployment Steps

### Step 1: Obtain External ID

1. Log in to Zilliz Cloud console
2. Navigate to your organization settings
3. Copy the External ID for BYOC projects

### Step 2: Configure Variables

Edit `terraform.tfvars.json`:

```json
{
  "region": "us-west-2",
  "vpc_cidr": "10.0.0.0/16",
  "name": "my-byoc-project",
  "ExternalId": "your-external-id-from-zilliz",
  "enable_private_link": false
}
```

### Step 3: Review Configuration

Review `main.tf` to understand what resources will be created. This example:
- Creates S3 buckets
- Creates IAM roles (cross-account, EKS, storage)
- Optionally creates VPC resources if needed

### Step 4: Initialize Terraform

```bash
terraform init
```

### Step 5: Review Plan

```bash
terraform plan
```

Verify that the plan matches your expectations, especially:
- S3 bucket names
- IAM role names
- VPC resources (if creating new)

### Step 6: Apply Configuration

```bash
terraform apply
```

Review the plan and type `yes` to confirm.

## Outputs

After successful deployment, Terraform will output:

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC ID (if created) |
| `subnet_id` | List of subnet IDs (if created) |
| `security_group_id` | Security group ID (if created) |
| `bucket_name` | S3 bucket name |
| `cross_account_role_arn` | Cross-account IAM role ARN |
| `eks_role_arn` | EKS IAM role ARN |
| `storage_role_arn` | Storage IAM role ARN |
| `external_id` | External ID for role assumption |
| `endpoint_id` | VPC endpoint ID (if PrivateLink enabled) |

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
external_id = "your-external-id"
endpoint_id = "vpce-xxxxxxxxxxxx"
```

## Using Existing Resources

### Option 1: Use Existing VPC

If you want to use an existing VPC, you can modify `main.tf` to use data sources:

```hcl
data "aws_vpc" "existing" {
  id = "vpc-xxxxxxxxxxxx"
}

data "aws_subnets" "existing" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}
```

Then reference these in your module calls.

### Option 2: Use Existing IAM Roles

If you have existing IAM roles, you can:
1. Skip the IAM module
2. Use data sources to reference existing roles
3. Pass the role ARNs directly to Zilliz Cloud console

## Integration with Zilliz Cloud Console

After deployment, use the outputs to configure your BYOC project in the Zilliz Cloud console:

1. **VPC Configuration**:
   - VPC ID: Use `vpc_id` output
   - Subnet IDs: Use `subnet_id` output
   - Security Group IDs: Use `security_group_id` output

2. **IAM Roles**:
   - Cross-account Role: Use `cross_account_role_arn` output
   - EKS Role: Use `eks_role_arn` output
   - Storage Role: Use `storage_role_arn` output

3. **Storage**:
   - S3 Bucket: Use `bucket_name` output

4. **PrivateLink** (if enabled):
   - VPC Endpoint ID: Use `endpoint_id` output

## Resource Details

### Created Resources

This example creates:

1. **S3 Resources**:
   - S3 bucket for Milvus storage (`{name}-milvus`)

2. **IAM Resources**:
   - Cross-account role for Zilliz management
   - EKS role for cluster operations
   - Storage role for S3 access

3. **VPC Resources** (optional):
   - VPC with subnets
   - Security groups
   - Internet Gateway / NAT Gateway

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

This creates a VPC endpoint for secure, private connectivity to Zilliz Cloud services.

## Security Considerations

1. **External ID**: Always use the External ID from Zilliz Cloud console for security
2. **IAM Roles**: Review IAM role policies to ensure they meet your security requirements
3. **S3 Bucket**: Ensure bucket has appropriate access controls
4. **VPC**: Use private subnets for compute resources when possible

## Troubleshooting

### Common Issues

**Error: "ExternalId mismatch"**
- Ensure you're using the correct External ID from Zilliz Cloud console
- External ID is case-sensitive

**Error: "VPC not found"**
- Verify VPC ID exists in your AWS account
- Check region matches your VPC region

**Error: "BucketAlreadyExists"**
- S3 bucket names must be globally unique
- Change the `name` variable to use a unique bucket name

**Error: "Insufficient permissions"**
- Verify your AWS credentials have permissions to create S3 buckets and IAM roles
- Check IAM policies for required actions

### Verification

Verify resources in AWS Console:
- S3: S3 → Buckets
- IAM: IAM → Roles
- VPC: EC2 → VPCs (if created)

## Cleanup

To destroy all created resources:

```bash
terraform destroy
```

**Note**: Only resources created by Terraform will be destroyed. Existing resources (VPC, subnets, etc.) will remain.

## Best Practices

1. **Use Separate Accounts**: Consider using a separate AWS account for BYOC deployments
2. **Tag Resources**: Add tags to resources for better organization
3. **Monitor Costs**: Set up cost alerts for S3 and other resources
4. **Backup**: Implement backup strategies for S3 buckets
5. **Access Control**: Regularly review IAM role permissions

## Related Documentation

- [AWS Requirements](../AWS Requirements.md)
- [AWS BYOC Standard Example](../aws-project-byoc-standard/README.md) - For automated deployment
- [AWS BYOC-I Example](../aws-project-byoc-I/README.md) - For customer-managed VPC with EKS
- [Zilliz Cloud Documentation](https://docs.zilliz.com/)

