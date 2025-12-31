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

variable "storage_container_scope" {
  description = "Scope for storage container role assignment (e.g., /subscriptions/.../containers/container-name)"
  type        = string
}

variable "custom_tags" {
  description = "Custom tags to apply to all resources (merged with Vendor=zilliz-byoc tag)"
  type        = map(string)
  default     = {}
}