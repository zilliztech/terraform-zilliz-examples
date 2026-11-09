# Provisioning Azure Zilliz BYOC Project 

## Overview
The Azure BYOC-I example provides:
- Azure Virtual Network (VNet) configuration
- Azure Storage Account for Milvus storage
- Azure Kubernetes Service (AKS) cluster setup
- Managed Identities for authentication
- Private Endpoint configuration (optional)

## Prerequisites

Ensure that you are the owner of a BYOC-I organization.

## Procedures

### Step 1: Prepare the deployment environment

A deployment environment is a local machine, a virtual machine (VM), or a CI/CD pipeline configured to run the Terraform configuration files and deploy the data plane of your BYOC-I project. In this step, you need to:

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

### Step 2: Configure input values to your terraform template

Navigate to `terraform.tfvars.json` and configure input values to your terraform template.

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `subscription_id` | The ID of the Azure subscription | `string` | — | Yes |
| `resource_group_name` | Name of the Azure resource group | `string` | — | Yes |
| `project_id` | BYOC Project ID | `string` | — | Yes |
| `dataplane_id` | BYOC Dataplane ID | `string` | — | Yes |
| `vnet` | Virtual Network configuration | `object` | `{}` | No |
| `vnet.cidr` | CIDR block for the virtual network | `string` | `"10.0.0.0/16"` | No |
| `storage` | Storage Account configuration | `object` | `{}` | No |
| `storage.account_tier` | Storage account tier | `string` | `"Standard"` | No |
| `storage.account_replication_type` | Storage replication type | `string` | `"RAGRS"` | No |
| `storage.account_kind` | Storage account kind | `string` | `"StorageV2"` | No |
| `storage.minimum_tls_version` | Minimum TLS version | `string` | `"TLS1_2"` | No |
| `storage.allow_blob_public_access` | Allow blob public access | `bool` | `false` | No |
| `storage.network_default_action` | Default network action | `string` | `"Allow"` | No |
| `storage.public_network_access_enabled` | Enable public network access | `bool` | `true` | No |
| `storage.allowed_subnet_names` | Subnet names to allow (empty = all) | `list(string)` | `[]` | No |
| `customer_acr` | Customer ACR configuration | `object` | `{}` | No |
| `customer_acr.name` | ACR name | `string` | `""` | No |
| `customer_acr.prefix` | ACR prefix | `string` | `""` | No |
| `env` | Environment name | `string` | `"Production"` | No |
| `tags` | Custom tags to apply to resources | `map(string)` | `{}` | No |

Example minimal configuration (`terraform.tfvars.json`):
```json
{
  "subscription_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "resource_group_name": "rg-my-byoc-project",
  "project_id": "proj-xxxxxxxxxx",
  "dataplane_id": "zilliz-byoc-azure-westus3-xxxxx"
}
```

Example configuration with custom options:
```json
{
  "subscription_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "resource_group_name": "rg-my-byoc-project",
  "project_id": "proj-xxxxxxxxxx",
  "dataplane_id": "zilliz-byoc-azure-westus3-xxxxx",
  "vnet": {
    "cidr": "10.1.0.0/16"
  },
  "storage": {
    "account_tier": "Premium",
    "account_replication_type": "LRS"
  },
  "tags": {
    "Environment": "Production",
    "Team": "Data"
  }
}
```

### Step 3: Deploy to your Azure environment

Run the following commands to initialize the Terraform environment and apply the configuration:

Initialize Terraform: `terraform init`

Verify those resources will be created by Terraform: `terraform plan`

Apply the Configuration: `terraform apply`

Review the plan when prompted and type yes to confirm and proceed with the resource creation.

### Step 4: Verify Deployment

After the terraform apply command completes, verify that all resources have been successfully created. You can check the Azure Portal or use the Terraform state output for confirmation.

Output:

| Name | Description |
|------|-------------|
| `vnet_id` | ID of the virtual network |
| `vnet_name` | Name of the virtual network |
| `subnet_ids` | Map of subnet names to their IDs |
| `subnet_address_prefixes` | Map of subnet names to their address prefixes |
| `nat_gateway_id` | ID of the NAT Gateway |
| `storage_account_id` | ID of the storage account |
| `storage_account_name` | Name of the storage account |
| `storage_account_primary_blob_endpoint` | Primary blob endpoint URL |
| `storage_container_name` | Name of the storage container |
| `storage_identities` | Storage identities (list of {client_id, principal_id, resource_id}) |
| `zilliz_private_endpoint_id` | ID of the Zilliz Cloud private endpoint |
| `zilliz_private_endpoint_name` | Name of the Zilliz Cloud private endpoint |
| `zilliz_private_endpoint_ip_address` | IP address of the Zilliz Cloud private endpoint (sensitive) |
| `zilliz_private_dns_zone_id` | ID of the private DNS zone for Zilliz Cloud |
| `zilliz_private_dns_zone_name` | Name of the private DNS zone for Zilliz Cloud |
| `aks_cluster_id` | ID of the AKS cluster |
| `aks_cluster_name` | Name of the AKS cluster |
| `aks_cluster_fqdn` | FQDN of the AKS cluster |
| `aks_cluster_private_fqdn` | Private FQDN of the AKS cluster |
| `aks_kube_config` | Kubernetes configuration for the AKS cluster (sensitive) |


## File Structure

```
azure-project-byoc-I/
├── main.tf              # Module execution (calls Azure modules)
├── variables.tf         # Input variable definitions
├── locals.tf            # Configuration abstraction layer
├── outputs.tf           # Output values
├── provider.tf          # Provider configuration
├── terraform.tfvars.json # Example configuration
└── README.md            # This file
```

## Milvus Client-Side Encryption with an Existing Azure AES Key

CSE is disabled by default. The default deployment keeps the existing Storage Account and storage identity behavior and creates no CSE identity or Key permissions.

For a **new DataPlane**, supply an existing AES (`oct-HSM`) Key in an Azure RBAC-enabled Key Vault. The Key must allow `encrypt` and `decrypt`. It can be in another resource group in the deployment subscription. Supply a versionless Key URL; do not append a Key version.

```hcl
enable_cse = true
azure_cse_key_identifier = "https://customer-vault.vault.azure.net/keys/customer-key"
azure_cse_key_vault_id   = "/subscriptions/<subscription-id>/resourceGroups/<key-resource-group>/providers/Microsoft.KeyVault/vaults/customer-vault"
```

Use these values alongside the normal `project_id`, `dataplane_id`, `subscription_id` and `resource_group_name` inputs, then run `terraform plan` and review the resources before `terraform apply`.

Terraform creates a dedicated CSE managed identity and a federated credential trusting this DataPlane's AKS issuer and `milvus-tool/milvus-bucket` service account. It grants **Key Vault Crypto User** at the existing **Key scope**. No Storage Account or Vault-wide crypto grant is added, and storage identities and their Blob access remain unchanged. The existing Key is never owned or deleted by Terraform.

The Terraform caller needs Vault/Key read permissions, managed identity and federation creation permissions in the DataPlane resource group, and role-assignment creation permissions at the target Key. The Vault must already use Azure RBAC and allow the deployment environment and DataPlane to reach its data endpoint. Terraform does not change the Vault's networking or authorization model. Azure IAM propagation can delay registration; retry the failed registration workflow after propagation if needed.

The provider reports `azure.cse.identity`, `azure.cse.tenant_id` and `azure.cse.default_key_identifier` to Zilliz Cloud only after federation and IAM resources exist. The platform stores the dedicated identity as `cseIdentity`, the tenant as `azureTenantId`, and the default Key as `defaultAzureCseKeyIdentifier`, then verifies and registers the CMEK integration during DataPlane creation. Outputs `cse_identity` and `cse_key_identifier` expose the configured values.

This example requires a Zilliz Cloud provider build that supports the optional `azure.cse` schema. The existing minimum provider constraint alone does not guarantee that support; select the release containing Azure BYOC CSE or the corresponding development build before initialization.

The existing `zillizcloud_byoc_i_project` lifecycle ignores changes to `azure` after creation and prevents destruction. Changing these CSE variables does **not** retroactively enable CSE on an already-created DataPlane; use the platform's documented existing-DataPlane integration procedure instead. Do not replace a running DataPlane to force a configuration update.

This phase supports existing AES Keys only. RSA/EC, Managed HSM endpoints, cross-subscription Keys and automatic Key creation are not supported. CSE is independent of cloud-side storage encryption (SSE); enabling it does not set a Storage Account default encryption Key, AKS Secrets Key or node disk Key.

See the [CSE module](../../modules/azure/byoc_i/cmek/README.md) for permission and lifecycle details.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6 |
| azurerm | >= 4.0 |
| zillizcloud | >=0.6.26 |

## Related Modules

- [default-virtual-networks](../../modules/azure/byoc_i/default-virtual-networks/README.md)
- [default-storageaccount](../../modules/azure/byoc_i/default-storageaccount/README.md)
- [default-storage-identity](../../modules/azure/byoc_i/default-storage-identity/README.md)
- [default-privatelink](../../modules/azure/byoc_i/default-privatelink/README.md)
- [default-aks](../../modules/azure/byoc_i/default-aks/README.md)
- [cmek](../../modules/azure/byoc_i/cmek/README.md)


## Stay Updated

For updates on Azure BYOC-I support:
- Check [Zilliz Cloud Documentation](https://docs.zilliz.com/)
- Review [Zilliz Cloud Release Notes](https://docs.zilliz.com/docs/release-notes)
- Contact Zilliz Support


## Support

For questions about Azure BYOC-I availability:
- Contact Zilliz Support
- Check [Zilliz Cloud Documentation](https://docs.zilliz.com/)
- Review [Zilliz Community Forums](https://github.com/milvus-io/milvus/discussions)
