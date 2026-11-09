# ARM template parameters mapping
variable "storage_account_name" {
  description = "The name of the storage account (ARM: storageAccounts_zillizvdceastus_name)"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location/region where the storage account will be created"
  type        = string
}

# ARM template storage account properties
variable "account_tier" {
  description = "Defines the Tier to use for this storage account (ARM: sku.tier)"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Defines the type of replication to use for this storage account (ARM: sku.name)"
  type        = string
  default     = "RAGRS"
}

variable "account_kind" {
  description = "Defines the Kind of account (ARM: kind)"
  type        = string
  default     = "StorageV2"
}

variable "minimum_tls_version" {
  description = "The minimum supported TLS version for the storage account (ARM: properties.minimumTlsVersion)"
  type        = string
  default     = "TLS1_2"
}

variable "allow_blob_public_access" {
  description = "Allow or disallow public access to all blobs or containers (ARM: properties.allowBlobPublicAccess)"
  type        = bool
  default     = false
}

variable "allow_shared_key_access" {
  description = "Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key (ARM: properties.allowSharedKeyAccess)"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Whether the public network access is enabled (ARM: properties.publicNetworkAccess)"
  type        = bool
  default     = true
}

variable "allow_cross_tenant_replication" {
  description = "Allow or disallow cross AAD tenant object replication (ARM: properties.allowCrossTenantReplication)"
  type        = bool
  default     = false
}

variable "require_infrastructure_encryption" {
  description = "Is infrastructure encryption enabled (ARM: properties.encryption.requireInfrastructureEncryption)"
  type        = bool
  default     = false
}

variable "access_tier" {
  description = "Defines the access tier for BlobStorage and StorageV2 accounts (ARM: properties.accessTier)"
  type        = string
  default     = "Hot"
}

# ARM template networkAcls properties
variable "network_default_action" {
  description = "Specifies the default action of allow or deny when no other rules match (ARM: properties.networkAcls.defaultAction)"
  type        = string
  default     = "Allow"
}

variable "network_bypass" {
  description = "Specifies whether traffic is bypassed for Logging/Metrics/AzureServices (ARM: properties.networkAcls.bypass)"
  type        = list(string)
  default     = ["AzureServices"]
}

variable "ip_rules" {
  description = "List of public IP or IP ranges in CIDR Format (ARM: properties.networkAcls.ipRules)"
  type        = list(string)
  default     = []
}

variable "virtual_network_subnet_ids" {
  description = "A list of virtual network subnet ids to secure the storage account (ARM: properties.networkAcls.virtualNetworkRules)"
  type        = list(string)
}

# Note: Blob and File service properties are configured directly on the storage account
# Additional service-specific configurations can be added here if needed

variable "custom_tags" {
  description = "Custom tags to apply to all resources (merged with Vendor=zilliz-byoc tag)"
  type        = map(string)
  default     = {}
}

# Container configuration variables
variable "container_name" {
  description = "The name of the storage container for BYOC data"
  type        = string
}

variable "container_access_type" {
  description = "The access type for the storage container"
  type        = string
  default     = "private"
}

variable "container_metadata" {
  description = "Metadata for the storage container"
  type        = map(string)
  default = {
    "purpose" = "zilliz-byoc-storage-container"
  }
}


variable "customer_managed_key" {
  description = "Existing same-tenant RBAC Key Vault key for Blob/File SSE. Null uses Microsoft-managed keys; omit key_version for automatic rotation."
  type = object({
    key_vault_id = string
    key_name     = string
    key_version  = optional(string)
  })
  default = null

  validation {
    condition = var.customer_managed_key == null ? true : (
      can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.KeyVault/vaults/[^/]+$", var.customer_managed_key.key_vault_id)) &&
      can(regex("^[a-zA-Z0-9-]{1,127}$", var.customer_managed_key.key_name)) &&
      (var.customer_managed_key.key_version == null ? true : can(regex("^[a-fA-F0-9]{32}$", var.customer_managed_key.key_version)))
    )
    error_message = "Provide a Key Vault ARM resource ID, a valid key name, and optionally a 32-character hexadecimal key version."
  }
}

variable "enable_cmk_sse" {
  description = "Allow customer-managed SSE when a key is supplied. False uses platform-managed encryption; Azure SSE itself cannot be disabled."
  type        = bool
  default     = true
  nullable    = false
}
