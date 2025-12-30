# Terraform Permissions for AWS BYOC-I Deployment

This directory contains AWS IAM policy documents that define the minimum required permissions for running Terraform to deploy a Zilliz BYOC-I project. These policies follow the principle of least privilege and are organized by AWS service category.

## Overview

When deploying a BYOC-I project using Terraform, your AWS credentials need specific permissions to create and manage various AWS resources. The permissions are split into four policy files based on the AWS services they cover:

- **byoc-i-vpc.json** - VPC and networking resources
- **byoc-i-iam.json** - IAM roles and policies
- **byoc-i-s3.json** - S3 bucket operations
- **byoc-i-eks.json** - EKS cluster and node group management

## Policy Files

### byoc-i-vpc.json

This policy grants permissions for managing VPC and networking resources required for BYOC-I deployment.

**Key Permissions:**
- **VPC Management**: Create, modify, describe, and delete VPCs
- **Subnet Operations**: Create and delete subnets
- **Security Groups**: Create, modify, and delete security groups and their rules
- **Route Tables**: Create, associate, and manage route tables
- **Internet Gateways**: Create, attach, and detach internet gateways
- **NAT Gateways**: Create and delete NAT gateways with Elastic IPs
- **VPC Endpoints**: Create and delete VPC endpoints for AWS services
- **Launch Templates**: Create and delete EC2 launch templates
- **Route53**: Associate VPCs with hosted zones
- **Tagging**: Create and delete tags on VPC resources

**Resources Covered:**
- VPCs, Subnets, Security Groups
- Route Tables, Internet Gateways, NAT Gateways
- VPC Endpoints, Launch Templates
- Network Interfaces, Elastic IPs

### byoc-i-iam.json

This policy grants permissions for managing IAM roles and policies required for BYOC-I deployment.

**Key Permissions:**
- **Role Management**: Create, get, list, attach/detach policies, and delete IAM roles
- **Policy Management**: Create, get, list versions, and delete IAM policies
- **Tagging**: Tag and untag roles and policies
- **Identity Verification**: Get caller identity (STS)

**Resources Covered:**
- IAM Roles (`arn:aws:iam::*:role/*`)
- IAM Policies (`arn:aws:iam::*:policy/*`)

**Note:** This policy allows managing roles and policies across all accounts in your organization. In production environments, consider restricting the resource ARNs to specific role/policy name patterns.

### byoc-i-s3.json

This policy grants permissions for managing S3 buckets used for Milvus storage in BYOC-I deployment.

**Key Permissions:**
- **Bucket Operations**: Create, list, get configuration, and delete S3 buckets
- **Bucket Configuration**: Manage bucket tagging, policies, ACLs, CORS, versioning, encryption, and public access settings
- **Object Tagging**: Put, get, and delete object tags
- **Bucket Listing**: List all buckets in the account

**Resources Covered:**
- S3 Buckets (`arn:aws:s3:::*`)
- S3 Objects (`arn:aws:s3:::*/*`)

**Note:** The policy allows access to all buckets. For enhanced security, consider restricting to specific bucket names or prefixes.

### byoc-i-eks.json

This policy grants permissions for managing EKS clusters, node groups, and related resources required for BYOC-I deployment.

**Key Permissions:**
- **Service-Linked Roles**: Create EKS service-linked roles for cluster and node group management
- **OIDC Provider**: Create, tag, get, and delete OpenID Connect providers (with `Vendor=zilliz-byoc` tag requirement)
- **IAM Role Management**: Read EKS roles and pass roles to EKS service
- **EC2 Resources**: Create launch templates, run instances, and manage tags (with `Vendor=zilliz-byoc` tag requirement)
- **EKS Cluster Operations**: Create, update, describe, tag, and delete EKS clusters
- **Node Group Operations**: Create, update, describe, and delete EKS node groups
- **Addon Management**: Create, update, describe, and delete EKS addons
- **Access Entry Management**: Create, update, describe, and delete EKS access entries and pod identity associations

**Resources Covered:**
- EKS Clusters (`arn:aws:eks:*:*:cluster/*`)
- EKS Node Groups (`arn:aws:eks:*:*:nodegroup/*/*/*`)
- EKS Addons (`arn:aws:eks:*:*:addon/*/*/*`)
- EKS Access Entries (`arn:aws:eks:*:*:access-entry/*/*/*/*/*`)
- Pod Identity Associations (`arn:aws:eks:*:*:podidentityassociation/*/*`)
- EC2 Launch Templates, Instances, Volumes, Network Interfaces

**Security Features:**
- Most create/update operations require the `Vendor=zilliz-byoc` tag
- Resource-level permissions with tag-based conditions
- Supports both resource tags and request tags for flexible tagging scenarios

## Usage

### Option 1: Attach Policies to an IAM User

1. Create an IAM user for Terraform operations
2. Create IAM policies from these JSON files:
   ```bash
   aws iam create-policy \
     --policy-name BYOC-I-VPC-Policy \
     --policy-document file://byoc-i-vpc.json
   
   aws iam create-policy \
     --policy-name BYOC-I-IAM-Policy \
     --policy-document file://byoc-i-iam.json
   
   aws iam create-policy \
     --policy-name BYOC-I-S3-Policy \
     --policy-document file://byoc-i-s3.json
   
   aws iam create-policy \
     --policy-name BYOC-I-EKS-Policy \
     --policy-document file://byoc-i-eks.json
   ```
3. Attach all policies to your IAM user:
   ```bash
   aws iam attach-user-policy \
     --user-name terraform-user \
     --policy-arn arn:aws:iam::ACCOUNT_ID:policy/BYOC-I-VPC-Policy
   # Repeat for other policies
   ```

### Option 2: Attach Policies to an IAM Role

1. Create an IAM role for Terraform operations
2. Create IAM policies from these JSON files (same as Option 1)
3. Attach all policies to your IAM role:
   ```bash
   aws iam attach-role-policy \
     --role-name terraform-role \
     --policy-arn arn:aws:iam::ACCOUNT_ID:policy/BYOC-I-VPC-Policy
   # Repeat for other policies
   ```

## Security Best Practices

1. **Principle of Least Privilege**: These policies provide the minimum required permissions. Do not grant additional permissions unless necessary.

2. **Resource Restrictions**: Consider restricting resource ARNs to specific patterns:
   - Limit IAM role/policy ARNs to specific naming patterns
   - Restrict S3 bucket ARNs to specific bucket names or prefixes
   - Limit VPC resources to specific VPC IDs or tags

3. **Tag-Based Access Control**: The EKS policy uses tag-based conditions (`Vendor=zilliz-byoc`). Ensure all resources created by Terraform are properly tagged.

4. **Separate Accounts**: Consider using a separate AWS account for BYOC deployments to isolate resources and limit blast radius.

5. **Audit Logging**: Enable AWS CloudTrail to audit all API calls made by Terraform.

6. **Regular Review**: Periodically review and update these policies as AWS services evolve and new permissions may be required.

## Troubleshooting

### Common Permission Errors

**Error: `AccessDenied: User is not authorized to perform: eks:CreateCluster`**
- **Solution**: Ensure `byoc-i-eks.json` policy is attached and includes EKS create permissions.

**Error: `AccessDenied: User is not authorized to perform: iam:CreateRole`**
- **Solution**: Ensure `byoc-i-iam.json` policy is attached and includes IAM role creation permissions.

**Error: `AccessDenied: User is not authorized to perform: s3:CreateBucket`**
- **Solution**: Ensure `byoc-i-s3.json` policy is attached and includes S3 bucket creation permissions.

**Error: `AccessDenied: User is not authorized to perform: ec2:CreateVpc`**
- **Solution**: Ensure `byoc-i-vpc.json` policy is attached and includes VPC creation permissions.

### Verifying Permissions

Test your permissions using AWS CLI:

```bash
# Test VPC permissions
aws ec2 describe-vpcs

# Test IAM permissions
aws iam get-user --user-name your-username

# Test S3 permissions
aws s3 ls

# Test EKS permissions
aws eks list-clusters
```

## Additional Resources

- [AWS IAM Policy Reference](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Zilliz BYOC-I Documentation](https://docs.zilliz.com/docs/byoc-i-overview)

## Policy Version

These policies use IAM policy version `2012-10-17`, which is the current version supported by AWS IAM.

## Support

For issues or questions regarding these permissions, please:
1. Check the [Zilliz Documentation](https://docs.zilliz.com/)
2. Review AWS CloudTrail logs for detailed error messages
3. Contact Zilliz Support with specific error messages and CloudTrail event IDs

