# Azure Storage Identity Module

This Terraform module creates a User Assigned Managed Identity for accessing Azure Storage accounts in Zilliz BYOC deployments.

## Features

- Creates User Assigned Managed Identity
- Configures Storage Blob Data Contributor role assignment on storage account scope
- Implements security best practices with least privilege
- Tags resources with Vendor=zilliz-byoc tag

## Usage

```hcl
module "storage_identity" {
  source = "../../modules/azure/storage-identity"

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
| storage_identity_object_id | The ID of the storage user assigned managed identity |
| storage_identity_client_id | The client ID of the storage user assigned managed identity |
| storage_identity_principal_id | The principal ID of the storage user assigned managed identity |

## Identity Details

### Storage Identity

The storage identity is used by workloads (e.g., Milvus) to access Azure Storage accounts.

**Role Assignments:**
- **Storage Blob Data Contributor** on storage account scope
  - Allows read/write access to blobs in the specified storage account
  - Scoped to the specific storage account

**Identity Naming:**
- The identity name is automatically prefixed with "zilliz-byoc-" (e.g., `zilliz-byoc-{name}`)

**Tags:**
- All resources are tagged with `Vendor=zilliz-byoc`
- Additional tags can be provided via `tags` or `custom_tags` variables

## Security Considerations

- Follows the principle of least privilege
- Role assignment is scoped to specific storage account
- No access to other storage accounts
- Uses User Assigned Managed Identity (not System Assigned) for better control

