variable "name" {
  description = "Base name for the storage identity"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "storage_account_scope" {
  description = "Scope for storage account role assignment (e.g., /subscriptions/.../storageAccounts/account-name)"
  type        = string
}

variable "custom_tags" {
  description = "Custom tags to apply to all resources (merged with Vendor=zilliz-byoc tag)"
  type        = map(string)
  default     = {}
}