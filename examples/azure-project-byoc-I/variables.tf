# ============================================================================
# Common Variables
# ============================================================================

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  nullable    = false

  validation {
    condition     = var.resource_group_name != ""
    error_message = "variable resource_group_name cannot be empty."
  }
}

variable "subscription_id" {
  description = "The ID of the Azure subscription"
  type        = string
  nullable    = false

  validation {
    condition     = var.subscription_id != ""
    error_message = "variable subscription_id cannot be empty."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}


# ============================================================================
# VNet Module Configuration
# ============================================================================

variable "vnet" {
  description = "Virtual Network configuration. All options have defaults."
  type = object({
    # CIDR block for the virtual network (default: 10.0.0.0/16)
    cidr = optional(string, "10.0.0.0/16")
  })
  nullable = false
  default  = {}
}

# ============================================================================
# Storage Account Module Configuration
# ============================================================================

variable "storage" {
  description = "Storage Account configuration. All options have defaults. By default, allows access from all VNet subnets."
  type = object({
    account_tier                  = optional(string, "Standard")
    account_replication_type      = optional(string, "RAGRS")
    account_kind                  = optional(string, "StorageV2")
    minimum_tls_version           = optional(string, "TLS1_2")
    allow_blob_public_access      = optional(bool, false)
    network_default_action        = optional(string, "Allow")
    public_network_access_enabled = optional(bool, true)
    # Optional: Specify subnet names to allow (empty list = allow all VNet subnets)
    allowed_subnet_names  = optional(list(string), [])
    container_metadata    = optional(map(string), {})
    container_access_type = optional(string, "private")
  })
  nullable = false
  default  = {}
}

variable "customer_acr" {
  description = "Customer ACR (Azure Container Registry) configuration. If provided, will be passed to ext_config."
  type = object({
    name   = optional(string, "")
    prefix = optional(string, "")
  })
  default = {}
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "Production"
}

variable "project_id" {
  description = "BYOC Project ID"
  type        = string
  nullable    = false
}

variable "dataplane_id" {
  description = "BYOC Dataplane ID"
  type        = string
  nullable    = false
}