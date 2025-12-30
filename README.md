# Zilliz BYOC Terraform Examples

This repository contains Terraform examples and reusable modules for deploying Zilliz Cloud Bring Your Own Cloud (BYOC) projects across multiple cloud providers.

## Quick Start

1. **Browse available examples**: See [`examples/`](./examples/) directory
2. **Choose your deployment type**: AWS, GCP, or Azure
3. **Follow the example-specific guide**: Each example includes detailed README
4. **Deploy**: `terraform init && terraform plan && terraform apply`

## What's Included

- **Examples**: Ready-to-use Terraform configurations for different deployment scenarios
- **Modules**: Reusable Terraform modules for common infrastructure components
- **IAM Policies**: Policy templates for required permissions
- **Documentation**: Step-by-step guides and best practices

## Examples

See [`examples/README.md`](./examples/README.md) for complete documentation of all available examples.

**Available Examples**:
- **AWS BYOC-I** - Customer-managed VPC with full customization
- **AWS BYOC Standard** - Automated full-stack deployment
- **AWS BYOC Manual** - Deployment with existing infrastructure
- **GCP BYOC Manual** - Google Cloud Platform deployment
- **Azure BYOC-I** - Azure deployment (coming soon)

## Modules

Reusable Terraform modules are available in [`modules/`](./modules/):

- **AWS**: `aws_byoc/` and `aws_byoc_i/` modules
- **GCP**: `gcp/` modules (VPC, GCS, GKE, IAM, PrivateLink)
- **Azure**: `azure/` modules (coming soon)

Each module includes its own documentation.

## Prerequisites

- **Terraform CLI** (>= 1.0.0) - [Install Guide](https://developer.hashicorp.com/terraform/downloads)
- **Cloud Provider Credentials** - AWS/GCP/Azure configured
- **Zilliz Cloud Account** - BYOC organization access and API key

See example-specific README files for detailed prerequisites and IAM permission requirements.

## Documentation

- **[Examples Index](./examples/README.md)** - Overview and comparison of all examples
- **[AWS BYOC-I Guide](./examples/aws-project-byoc-I/README.md)** - Detailed deployment guide
- **[AWS IAM Permissions](./examples/aws-project-byoc-I/terraform-permissions/README.md)** - Required IAM policies
- **[AWS Requirements](./examples/AWS-Requirements.md)** - AWS deployment requirements

## Resources

- [Zilliz Cloud Terraform Provider](https://registry.terraform.io/providers/zilliztech/zillizcloud/latest)
- [Zilliz Cloud Documentation](https://docs.zilliz.com/)
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)

## Support

For issues or questions:
1. Check the example-specific README files
2. Review cloud provider requirements
3. Consult [Zilliz Cloud Documentation](https://docs.zilliz.com/)
4. Contact Zilliz Support

## License

See [LICENSE](./LICENSE) file for details.
