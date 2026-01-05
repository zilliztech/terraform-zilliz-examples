# Zilliz BYOC Terraform Examples

This directory contains ready-to-use Terraform examples for deploying Zilliz Cloud Bring Your Own Cloud (BYOC) projects across different cloud providers and deployment scenarios.

## 📋 Overview

Each example in this directory demonstrates a complete deployment scenario with:
- Pre-configured Terraform modules
- Example variable files
- Step-by-step deployment guides
- Output examples

## 🗂️ Examples Directory

### AWS Examples

#### [AWS BYOC-I](./aws-project-byoc-I/)
**Customer-managed VPC with full customization**

Enterprise-grade deployment with customer-managed infrastructure:
- Customer-managed VPC, security groups, and subnets
- Customizable resource names (buckets, EKS clusters, IAM roles)
- Integration with existing ECR repositories
- Custom tags support
- VPC PrivateLink endpoint management

**Best for**: Enterprise deployments requiring compliance, customization, and full control over infrastructure.

**Key Features**:
- Customer-managed VPC and networking
- EKS cluster and node group management
- S3 bucket customization
- IAM role name customization
- ECR integration
- PrivateLink endpoint configuration
- Comprehensive IAM permissions documentation

**Documentation**: 
- [Deployment Guide](./aws-project-byoc-I/README.md)
- [IAM Permissions](./aws-project-byoc-I/terraform-permissions/README.md)

---

#### [AWS BYOC Standard](./aws-project-byoc-standard/)
**Automated full-stack deployment**

Creates all required AWS resources automatically:
- VPC, subnets, and security groups
- S3 buckets for Milvus storage
- IAM roles and policies (cross-account, EKS, storage)
- Zilliz Cloud BYOC project resource

**Best for**: Quick deployments, testing environments, and proof-of-concept projects.

**Key Features**:
- Fully automated resource provisioning
- Instance configuration (core, fundamental, search, index nodes)
- Optional PrivateLink support
- Instance auto-scaling configuration

**Documentation**: [README](./aws-project-byoc-standard/README.md)

---

#### [AWS BYOC Manual](./aws-project-byoc-manual/)
**Deployment with existing infrastructure**

Uses your existing AWS resources:
- Existing VPC and subnets
- Existing security groups
- Manual IAM role configuration

**Best for**: Production environments with existing infrastructure, compliance requirements, or when you need to reuse existing resources.

**Key Features**:
- Minimal resource creation
- Integration with existing VPC
- Manual External ID configuration
- Optional PrivateLink support

**Documentation**: [README](./aws-project-byoc-manual/README.md)

---

### GCP Examples

#### [GCP BYOC Manual](./gcp-project-byoc-manual/)
**Google Cloud Platform deployment**

Deploys Zilliz BYOC on Google Cloud Platform:
- VPC and subnet configuration
- GCS buckets for storage
- GKE cluster setup
- IAM service accounts
- Private Service Connect (optional)

**Best for**: Organizations using Google Cloud Platform infrastructure.

**Key Features**:
- GCP VPC and subnet management
- GCS bucket creation
- GKE cluster configuration
- Service account management
- Private Service Connect support
- Customizable resource names

**Documentation**: [README](./gcp-project-byoc-manual/README.md)

---

### Azure Examples

#### [Azure BYOC-I](./azure-project-byoc-I/)
**Azure-based BYOC-I deployment**

Azure deployment with customer-managed resources.

**Status**: Coming soon

**Best for**: Organizations using Microsoft Azure infrastructure.

**Documentation**: [README](./azure-project-byoc-I/README.md)

---

## 📚 Common Requirements

### AWS Deployment Requirements

See [AWS Requirements.md](./AWS Requirements.md) for detailed AWS deployment requirements including:
- VPC high availability best practices
- Private EKS cluster support
- Security group configurations
- Resource tagging requirements

### General Prerequisites

All examples require:

1. **Terraform CLI** (>= 1.0.0)
   - [Installation Guide](https://developer.hashicorp.com/terraform/downloads)

2. **Cloud Provider Credentials**
   - AWS: Configure using [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
   - GCP: Configure using `gcloud auth application-default login`
   - Azure: Configure using `az login`

3. **Zilliz Cloud Account**
   - Obtain API key from Zilliz Cloud console
   - Ensure BYOC organization access

4. **Required Permissions**
   - See example-specific README files for detailed permission requirements
   - AWS: See [IAM Permissions Guide](./aws-project-byoc-I/terraform-permissions/README.md)

## 🚀 Quick Start

1. **Choose an example** based on your cloud provider and requirements
2. **Navigate to the example directory**:
   ```bash
   cd examples/aws-project-byoc-I  # Example
   ```
3. **Review the README** for detailed instructions
4. **Configure variables**:
   - Copy sample variable files if available
   - Edit with your specific values
5. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## 📖 Documentation Structure

Each example directory contains:

```
example-name/
├── README.md              # Detailed deployment guide
├── main.tf                # Main Terraform configuration
├── variables.tf           # Variable definitions
├── provider.tf            # Provider configuration (if applicable)
├── terraform.tfvars.json  # Example variable values
└── terraform-permissions/ # IAM policy templates (if applicable)
    └── README.md          # Permissions documentation
```

## 🔗 Related Resources

- [Main Project README](../README.md)
- [Terraform Modules](../modules/)
- [Zilliz Cloud Documentation](https://docs.zilliz.com/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Zilliz Cloud Terraform Provider](https://registry.terraform.io/providers/zilliztech/zillizcloud/latest)

## 💡 Choosing the Right Example

| Example | Cloud | Infrastructure | Use Case |
|---------|-------|----------------|----------|
| AWS BYOC-I | AWS | Customer-managed | Enterprise, compliance, customization |
| AWS BYOC Standard | AWS | Automated | Quick deployments, testing |
| AWS BYOC Manual | AWS | Existing | Production with existing resources |
| GCP BYOC Manual | GCP | Customer-managed | GCP infrastructure |
| Azure BYOC-I | Azure | Customer-managed | Azure infrastructure |

## 🆘 Support

For issues or questions:

1. Check the example-specific README
2. Review [AWS Requirements](./AWS Requirements.md)
3. Consult [Zilliz Cloud Documentation](https://docs.zilliz.com/)
4. Contact Zilliz Support with specific error messages

