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

2. **Terraform CLI** (>= 1.5.0)
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
| `storage.enable_cmk_sse` | Allow Blob CMK when a key is supplied; false uses platform keys | `bool` | `true` | No |
| `disk` | Independent AKS disk encryption configuration | `object` | `{}` | No |
| `disk.enable_cmk_sse` | Allow disk CMK when a key is supplied; false uses platform keys | `bool` | `true` | No |
| `disk.customer_managed_key` | Existing key: `key_vault_id`, `key_name`, optional `key_version` | `object` | `null` | No |
| `storage.customer_managed_key` | Existing RBAC Key Vault key for Blob/File SSE: `key_vault_id`, `key_name`, optional `key_version` | `object` | `null` | No |
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
| `storage_sse_identity_id` | Dedicated SSE identity ID, or null when CMK is disabled |
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
| `disk_encryption_set_id` | Disk Encryption Set ID, or null with platform keys |
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

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| azurerm | >= 4.0 |
| zillizcloud | >=0.6.26 |

## Related Modules

- [default-virtual-networks](../../modules/azure/byoc_i/default-virtual-networks/README.md)
- [default-storageaccount](../../modules/azure/byoc_i/default-storageaccount/README.md)
- [default-storage-identity](../../modules/azure/byoc_i/default-storage-identity/README.md)
- [default-privatelink](../../modules/azure/byoc_i/default-privatelink/README.md)
- [default-aks](../../modules/azure/byoc_i/default-aks/README.md)


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

## Server-side encryption: Blob and AKS disks

Azure always encrypts Blob storage and managed disks at rest. Blob (`storage`)
and AKS disks (`disk`) independently accept `enable_cmk_sse` (default `true`) and
`customer_managed_key` (default `null`). The switch controls customer-managed
keys, not Azure's mandatory encryption.

| Switch | Custom key | Result |
| --- | --- | --- |
| omitted / true | omitted / null | Platform-managed encryption; no CMK resources |
| true | supplied | Customer-managed encryption using that key |
| false | supplied or omitted | Platform-managed encryption; supplied key is ignored |

The minimal configuration keeps platform keys for both storage and disks.
To use different customer keys, merge the following into `terraform.tfvars.json`:

```json
{
  "storage": {
    "enable_cmk_sse": true,
    "customer_managed_key": {
      "key_vault_id": "/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<vault>",
      "key_name": "byoc-blob-key"
    }
  },
  "disk": {
    "enable_cmk_sse": true,
    "customer_managed_key": {
      "key_vault_id": "/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<vault>",
      "key_name": "byoc-disk-key",
      "key_version": "0123456789abcdef0123456789abcdef"
    }
  }
}
```

Keys can be the same or different. Configure only `storage` for Blob CMK with
platform disk keys, or only `disk` for disk CMK with platform Blob keys. A false
switch never disables the other resource's CMK configuration. Replace the sample
version with a real key version, or omit it for automatic rotation.

### Resources and permissions

- Blob CMK requires `StorageV2`. Terraform creates a dedicated storage identity,
  grants `Key Vault Crypto Service Encryption User` on the selected key, and
  attaches that identity and key to the Storage Account. The account setting also
  applies to Azure Files, but this example does not provision or test file shares.
  Queue/Table retain their existing service-managed encryption settings.
- Disk CMK creates a Disk Encryption Set (DES) and a dedicated identity with
  key-scoped `Key Vault Crypto Service Encryption User`. A separate AKS
  control-plane identity receives Reader on the DES and Network Contributor on
  the AKS subnet before cluster creation. The existing resource-group Network
  Contributor assignment also targets this identity after creation. Platform-key
  deployments retain the existing SystemAssigned AKS identity.
- Existing keys and vaults remain customer-owned. Terraform does not create,
  rotate, or delete them. Outputs include `storage_sse_identity_id` and
  `disk_encryption_set_id` (null when the corresponding CMK is inactive).

### Key Vault prerequisites

Use an existing same-tenant Azure Key Vault with RBAC, soft delete and purge
protection enabled. Use an enabled RSA/RSA-HSM key supported by the target Azure
service, with wrap/unwrap operations available. Disk keys must be in the same
region as the DES/AKS cluster. This implementation does not support cross-tenant
keys, access-policy vaults, or Managed HSM.

The Terraform caller needs key metadata read access (`Get`), network access to
the vault data endpoint, permissions to create DES/managed identities and role
assignments at the relevant scopes, and the usual BYOC provisioning permissions.
Azure Storage and Disk Encryption Set must be able to access the vault; configure
the trusted-services bypass when restricting the Key Vault firewall.

RBAC assignment creation does not guarantee immediate propagation. If the first
apply fails with a Key Vault authorization error, check the identity, role and
firewall, wait for propagation, and retry the same apply.

### AKS scope and existing deployments

**OS disk CMK is cluster-wide, including the search pool's Ephemeral OS Disk.**
The node pool disk types remain unchanged. There is no per-pool exclusion in this
configuration. Newly provisioned Azure Disk CSI data volumes normally inherit
the cluster DES unless their StorageClass explicitly selects another DES. This
change does not migrate existing PVCs or independently configure local temporary
NVMe data disks, host encryption, or Milvus application-level CMEK.

**Adding, removing, or changing the cluster DES ID forces AKS replacement in the
AzureRM provider.** This includes switching between platform and customer keys.
For an existing deployment, inspect the plan and arrange migration before apply;
do not treat this as an in-place encryption toggle. Changing the key within the
same DES is a separate operation, subject to Azure's key-rotation requirements.

Blob CMK can be updated on the existing Terraform-managed Storage Account.
Do not use `require_infrastructure_encryption` to enable CMK: that separate
setting can replace the Storage Account. Do not independently manage the same
Storage Account CMK binding outside this module.

### Rotation

Omit `key_version` for a versionless key URL: Blob uses automatic key-version
updates and DES sets `auto_key_rotation_enabled = true`. Supplying a 32-character
version pins the key and disables automatic DES rotation. Terraform reads current
key metadata even when a version is pinned.

Blob checks for new key versions daily; retain the previous version for at least
24 hours. **Ephemeral OS nodes do not immediately adopt a new key version.** Keep
old key versions enabled until all affected nodes have been reimaged/recreated or
upgraded to adopt the new key, following the AKS rotation procedure. Automatic DES
rotation does not prove that all Ephemeral nodes have adopted the new version.

### Verification

```sh
az storage account show --resource-group <rg> --name <account> \
  --query '{source:encryption.keySource,key:encryption.keyvaultproperties}'
az aks show --resource-group <rg> --name <cluster> --query diskEncryptionSetId
az disk-encryption-set show --ids <des-id> \
  --query '{type:encryptionType,key:activeKey,rotation:rotationToLatestKeyVersionEnabled}'
az vmss show --resource-group <aks-node-rg> --name <vmss> \
  --query 'virtualMachineProfile.storageProfile.osDisk'
```

Platform mode should have `Microsoft.Storage` for Blob and no AKS DES. CMK mode
should have `Microsoft.Keyvault` and the selected DES/key. Inspect both a Managed
OS pool and the search Ephemeral pool's VMSS. Verify Milvus insert/query and
backup/restore in a test deployment before production rollout. Offline Terraform
tests do not validate Azure RBAC propagation or service-side encryption behavior.

References:

- [Azure Storage CMK](https://learn.microsoft.com/en-us/azure/storage/common/customer-managed-keys-configure-new-account)
- [AKS disk CMK, inheritance and rotation](https://learn.microsoft.com/en-us/azure/aks/azure-disk-customer-managed-keys)
- [AzureRM cluster DES replacement behavior](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#disk_encryption_set_id)
