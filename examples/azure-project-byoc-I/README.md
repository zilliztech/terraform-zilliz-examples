# Azure BYOC-I Deployment

This example demonstrates deploying Zilliz Cloud BYOC on Microsoft Azure with customer-managed resources.

## Status

🚧 **Coming Soon** - This example is currently under development.

## Overview

The Azure BYOC-I example will provide:
- Azure Virtual Network (VNet) configuration
- Azure Storage Account for Milvus storage
- Azure Kubernetes Service (AKS) cluster setup
- Managed Identities for authentication
- Private Endpoint configuration (optional)

## Prerequisites

Once available, this example will require:

1. **Azure Subscription**
   - Active Azure subscription with appropriate permissions
   - Required resource providers registered

2. **Terraform CLI** (>= 1.0.0)
   - [Installation Guide](https://developer.hashicorp.com/terraform/downloads)

3. **Azure Credentials** configured
   - Authenticate using: `az login`
   - Or set service principal credentials

4. **Zilliz Cloud Account**
   - Obtain API key from Zilliz Cloud console
   - Ensure BYOC-I organization access

## Expected Architecture

This example will use Azure modules:
- Azure Virtual Network (VNet)
- Azure Storage Account
- Azure Kubernetes Service (AKS)
- Azure Private Endpoints
- Managed Identities

## Stay Updated

For updates on Azure BYOC-I support:
- Check [Zilliz Cloud Documentation](https://docs.zilliz.com/)
- Review [Zilliz Cloud Release Notes](https://docs.zilliz.com/docs/release-notes)
- Contact Zilliz Support

## Related Examples

While waiting for Azure BYOC-I support, you can explore:
- [AWS BYOC-I Example](../aws-project-byoc-I/README.md) - Similar architecture on AWS
- [GCP BYOC Manual Example](../gcp-project-byoc-manual/README.md) - GCP deployment example

## Support

For questions about Azure BYOC-I availability:
- Contact Zilliz Support
- Check [Zilliz Cloud Documentation](https://docs.zilliz.com/)
- Review [Zilliz Community Forums](https://github.com/milvus-io/milvus/discussions)

