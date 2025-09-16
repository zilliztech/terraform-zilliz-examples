# AWS IAM Module for Zilliz BYOC

This Terraform module creates and manages the necessary IAM roles and policies for Zilliz Bring Your Own Cloud (BYOC) deployment on AWS. It sets up three main roles:

1. Cross Account Role
2. EKS Role
3. Storage Role

## Features

- Creates IAM roles with appropriate trust relationships
- Attaches necessary policies for EKS cluster management
- Sets up storage access permissions
- Configures cross-account access with external ID validation
- Implements security best practices with least privilege principles

## Usage

```hcl
module "aws_iam" {
  source = "path/to/modules/aws_byoc/aws_iam"

  name         = "your-project-name"
  ExternalId   = "your-external-id"
  bucketName   = "your-s3-bucket-name"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | The name of the BYOC project | `string` | n/a | yes |
| ExternalId | The external ID for the role | `string` | n/a | yes |
| bucketName | The name of the S3 bucket | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cross_account_role_arn | ARN of the cross-account IAM role |
| external_id | The external ID used for role assumption |
| storage_role_arn | ARN of the storage IAM role |
| eks_role_arn | ARN of the EKS IAM role |

## Role Details

### 1. Cross Account Role
The cross-account role allows Zilliz to manage resources in your AWS account with the following permissions:

- **EKS Management**
  - Create and manage EKS service-linked roles
  - Create and manage OpenID Connect providers
  - Pass roles to EKS service
  - Update trust policies for EKS roles

- **[EC2 Management](https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-tagging)**
  - Create and manage launch templates
  - Run EC2 instances
  - Manage instance tags
  - Create and manage volumes and network interfaces

- **IAM Management**
  - Read EKS role information
  - Pass roles to EKS service
  - Update trust policies after OIDC provider creation

### 2. EKS Role
The EKS role manages EKS cluster operations with the following capabilities:

- **Core EKS Policies**
  - AmazonEKSClusterPolicy
  - AmazonEKSWorkerNodePolicy
  - AmazonEKS_CNI_Policy
  - AmazonEKSVPCResourceController
  - AmazonEC2ContainerRegistryReadOnly

- **Additional Components**
  - AWS Load Balancer Controller
  - Cluster Autoscaler
  - EBS CSI Controller

- **Trust Relationships**
  - EKS service
  - EKS nodegroup service
  - EC2 service
  - OIDC provider for various service accounts

### 3. Storage Role for Milvus
The storage role manages S3 bucket access with the following permissions:

- **S3 Operations**
  - List bucket contents
  - Get objects
  - Put objects
  - Delete objects

- **Trust Relationships**
  - OIDC provider for service accounts:
    - milvus-*:milvus*
    - loki:loki*
    - index-pool:milvus*

## Security

- All roles implement the principle of least privilege
- External ID validation for cross-account access
- Resource-level permissions with appropriate conditions
- Tag-based access control for resources

## Tags

All resources are tagged with:
- `Vendor = "zilliz-byoc"`
- `Caller = <current-account-arn>`

## Notes

- The module requires AWS credentials to be configured
- External ID must be obtained from Zilliz
- S3 bucket must exist before applying this module