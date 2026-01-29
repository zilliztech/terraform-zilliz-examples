# Azure Storage Identity Module

This Terraform module creates a User Assigned Managed Identity for accessing Azure Storage accounts in Zilliz BYOC deployments.

## Features

- Creates a default User Assigned Managed Identity for storage access
- Creates 9 instance User Assigned Managed Identities (numbered 1-9) for workload isolation
- Configures Storage Blob Data Contributor role assignment on storage account scope for all identities
- Implements security best practices with least privilege
- Tags resources with Vendor=zilliz-byoc tag

## Usage

```hcl
module "storage_identity" {
  source = "../../modules/azure/byoc_i/default-storage-identity"

  name                  = "zilliz-byoc"
  location              = "East US"
  resource_group_name   = "rg-zilliz-byoc"
  storage_account_scope = "/subscriptions/.../providers/Microsoft.Storage/storageAccounts/mystorageaccount"

  custom_tags = {
    Environment = "Production"
    Project     = "Zilliz-BYOC"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| azurerm | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Base name for the storage identity (will be prefixed with "zilliz-byoc-") | `string` | n/a | yes |
| location | Azure region where resources will be created | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| storage_account_scope | Full resource ID of the storage account for role assignment (e.g., /subscriptions/.../storageAccounts/account-name) | `string` | n/a | yes |
| custom_tags | Custom tags to apply to all resources (merged with Vendor=zilliz-byoc tag) | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `storage_identity` | The default storage identity object with `object_id`, `client_id`, and `principal_id` |
| `instance_identities` | List of instance identity objects, each with `object_id`, `client_id`, and `principal_id` |

## Identity Details

### Storage Identity

The module creates one default storage identity and 9 instance identities, all used by workloads (e.g., Milvus) to access Azure Storage accounts.

**Role Assignments:**
- **Storage Blob Data Contributor** on storage account scope for all identities (default + instance)
  - Allows read/write access to blobs in the specified storage account
  - Scoped to the specific storage account

**Identity Naming:**
- Default identity: `{name}-storage-identity-default`
- Instance identities: `{name}-storage-identity-{1..9}`

**Tags:**
- All resources are tagged with `Vendor=zilliz-byoc`
- Additional tags can be provided via `tags` or `custom_tags` variables

## Security Considerations

- Follows the principle of least privilege
- Role assignment is scoped to specific storage account
- No access to other storage accounts
- Uses User Assigned Managed Identity (not System Assigned) for better control

