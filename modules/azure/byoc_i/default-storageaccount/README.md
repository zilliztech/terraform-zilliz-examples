# Azure Storage Account Module

This Terraform module creates an Azure Storage Account with containers for storing BYOC data, with optional customer-managed server-side encryption.

## Features

- Creates a StorageV2 storage account with Standard_RAGRS replication
- Configures all storage services (blob, file, queue, table) as per ARM template
- Creates a container for storing BYOC data
- Implements all security settings from the ARM template
- Supports an existing Azure Key Vault key for Blob/File SSE using a dedicated managed identity

## Resources Created

This module creates the following Azure resources:
- `azurerm_storage_account` - The storage account with blob and file service properties configured
- `azurerm_storage_container` - A container for storing BYOC data

**Note:** 
- Blob service properties (`blob_properties`) and file service properties (`share_properties`) are configured as part of the storage account resource, not as separate resources
- Queue and Table services are automatically created with StorageV2 accounts and don't require explicit configuration

## Usage

```hcl
module "storage_account" {
  source = "../../modules/azure/byoc_i/default-storageaccount"

  storage_account_name      = "zillizbyocstorage"
  resource_group_name       = "rg-zilliz-byoc"
  location                  = "East US"
  container_name            = "zilliz-byoc-data"
  virtual_network_subnet_ids = [
    "/subscriptions/.../subnets/milvus",
    "/subscriptions/.../subnets/default"
  ]

  # All other parameters use defaults
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| storage_account_name | The name of the storage account (must be globally unique, 3-24 characters, lowercase letters and numbers only) | `string` | n/a | yes |
| resource_group_name | The name of the resource group | `string` | n/a | yes |
| location | The location/region where the storage account will be created | `string` | n/a | yes |
| container_name | The name of the storage container for BYOC data | `string` | n/a | yes |
| virtual_network_subnet_ids | A list of virtual network subnet IDs to secure the storage account | `list(string)` | n/a | yes |
| customer_managed_key | Existing RBAC Key Vault key (`key_vault_id`, `key_name`, optional `key_version`) | `object` | `null` | no |
| account_tier | Defines the Tier to use for this storage account | `string` | `"Standard"` | no |
| account_replication_type | Defines the type of replication | `string` | `"RAGRS"` | no |
| account_kind | Defines the Kind of account | `string` | `"StorageV2"` | no |
| minimum_tls_version | The minimum supported TLS version | `string` | `"TLS1_2"` | no |
| allow_blob_public_access | Allow or disallow public access to all blobs or containers | `bool` | `false` | no |
| allow_shared_key_access | Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key | `bool` | `true` | no |
| public_network_access_enabled | Whether the public network access is enabled | `bool` | `true` | no |
| allow_cross_tenant_replication | Allow or disallow cross AAD tenant object replication | `bool` | `false` | no |
| require_infrastructure_encryption | Is infrastructure encryption enabled | `bool` | `false` | no |
| access_tier | Defines the access tier for BlobStorage and StorageV2 accounts | `string` | `"Hot"` | no |
| network_default_action | Specifies the default action of allow or deny when no other rules match | `string` | `"Allow"` | no |
| network_bypass | Specifies whether traffic is bypassed for Logging/Metrics/AzureServices | `list(string)` | `["AzureServices"]` | no |
| ip_rules | List of public IP or IP ranges in CIDR Format | `list(string)` | `[]` | no |
| container_access_type | The access type for the storage container | `string` | `"private"` | no |
| container_metadata | Metadata for the storage container | `map(string)` | `{"purpose" = "zilliz-byoc-storage-container"}` | no |
| custom_tags | Custom tags to apply to all resources (merged with Vendor=zilliz-byoc tag) | `map(string)` | `{}` | no |

**Note:** The following blob and file service properties are hardcoded in the module:
- Container delete retention: 7 days
- Blob delete retention: 7 days
- Versioning: disabled
- Share delete retention: 7 days

## Outputs

| Name | Description |
|------|-------------|
| sse_identity_id | Dedicated SSE identity ID, or null when CMK is disabled |
| storage_account_id | The ID of the storage account |
| storage_account_name | The name of the storage account |
| primary_access_key | The primary access key for the storage account (sensitive) |
| secondary_access_key | The secondary access key for the storage account (sensitive) |
| primary_blob_endpoint | The endpoint URL for blob storage in the primary location |
| secondary_blob_endpoint | The endpoint URL for blob storage in the secondary location |
| primary_blob_host | The hostname with port if applicable for blob storage in the primary location |
| secondary_blob_host | The hostname with port if applicable for blob storage in the secondary location |
| byoc_data_container_name | The name of the BYOC data container |
| byoc_data_container_id | The ID of the BYOC data container |

## Features Details

### Storage Account Configuration
- **Account Type**: StorageV2 with Standard tier and RAGRS (Read-Access Geo-Redundant Storage) replication
- **Security**: 
  - HTTPS traffic only enabled
  - Minimum TLS version: TLS 1.2
  - Blob public access disabled by default
  - Infrastructure encryption disabled by default
- **Network**: 
  - Public network access enabled by default
  - Network rules support VNet subnet restrictions
  - IP rules support for specific IP ranges
- **Retention Policies**:
  - Container delete retention: 7 days (hardcoded)
  - Blob delete retention: 7 days (hardcoded)
  - Share delete retention: 7 days (hardcoded)

### Container Configuration
- Creates a single container for storing BYOC data
- Container access type: private by default
- Metadata includes purpose tag: "zilliz-byoc-storage-container"

## Notes

- This module creates a Storage Account with a container for storing BYOC data
- Container name must be provided (required parameter)
- Virtual network subnet IDs must be provided to configure network access rules
- Some blob and file service properties are hardcoded (retention policies, versioning)
- Queue and Table services are automatically created with StorageV2 accounts

## Customer-managed SSE

Requires Terraform >= 1.3 and AzureRM >= 4.0, < 5.0. Pass this optional object:

```hcl
customer_managed_key = {
  key_vault_id = "/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<vault>"
  key_name     = "byoc-storage-key"
  # key_version = "0123456789abcdef0123456789abcdef" # optional; omit for rotation
}
```

Default: `null` (Microsoft-managed keys). Supported account kind: `StorageV2`.
The module reads the existing key, creates a dedicated user-assigned identity,
assigns `Key Vault Crypto Service Encryption User` at key scope, then attaches
both identity and CMK to Storage. `sse_identity_id` outputs the dedicated identity
ID, or `null` when disabled. Keys and vaults are never managed by this module.

See the [deployment guide](../../../../examples/azure-project-byoc-I/README.md#server-side-encryption-blob-and-aks-disks)
for RBAC/network prerequisites, rotation, existing accounts, and verification.
This is Blob/File SSE, not AKS disk encryption or Milvus application-level CMEK.
Queue/Table encryption settings remain unchanged.

Offline tests (Terraform >= 1.7 for mock providers):

```sh
terraform init -backend=false
terraform validate
terraform test
```

### CMK-SSE switch

`enable_cmk_sse` defaults to `true`.
With no `customer_managed_key`, Azure uses platform-managed encryption.
With a key supplied, CMK-SSE is enabled. Setting `enable_cmk_sse = false`
ignores the supplied key and uses platform-managed encryption without creating
CMK identities, roles, or key lookups. This switch never disables Azure's
mandatory server-side encryption.
