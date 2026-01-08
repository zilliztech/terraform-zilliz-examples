# ============================================================================
# Common Variables
# ============================================================================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}


# ============================================================================
# VNet Module Configuration
# ============================================================================

variable "vnet" {
  description = "Virtual Network configuration.D efault CIDR is 10.0.0.0/16."
  type = object({
    # Required when create_vnet is true: CIDR block for the virtual network
    cidr = optional(string)
    # Optional: Custom subnet configurations (only specify if you need to override defaults)
    custom_subnets = optional(map(object({
      # Optional: Override auto-calculated CIDR
      cidr = optional(string)
      # Optional: Additional service endpoints (Microsoft.Storage and Microsoft.Storage.Global are added automatically)
      service_endpoints = optional(list(string), [])
      # Optional: Enable public internet support (allows outbound HTTPS/443)
      public_support = optional(bool, false)
      # Optional: Advanced subnet configurations (rarely needed)
      private_link_service_network_policies_enabled = optional(bool, true)
      private_endpoint_network_policies_enabled     = optional(bool, true)
      delegation = optional(object({
        name         = string
        service_name = string
        actions      = list(string)
      }))
      security_group = optional(object({
        rules = list(object({
          name                       = string
          priority                   = number
          direction                  = string
          access                     = string
          protocol                   = string
          source_port_range          = optional(string)
          destination_port_range     = optional(string)
          source_address_prefix      = optional(string)
          destination_address_prefix = optional(string)
          description                = optional(string)
        }))
      }))
    })), {})
  })
  nullable = false

  validation {
    condition     = var.create_vnet ? (try(var.vnet.cidr, "") != "") : true
    error_message = "VNet CIDR is required when create_vnet is true."
  }
}

# ============================================================================
# Storage Account Module Configuration
# ============================================================================

variable "storage" {
  description = "Storage Account configuration. Name is required when create_storage_account is true, all other options use defaults. By default, allows access from all VNet subnets."
  type = object({
    # Required when create_storage_account is true: Name of the storage account (must be globally unique, 3-24 characters, lowercase letters and numbers only)
    name = optional(string)
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "RAGRS")
    account_kind             = optional(string, "StorageV2")
    minimum_tls_version      = optional(string, "TLS1_2")
    allow_blob_public_access = optional(bool, false)
    network_default_action   = optional(string, "Allow")
    public_network_access_enabled = optional(bool, true)
    # Optional: Specify subnet names to allow (empty list = allow all VNet subnets)
    allowed_subnet_names        = optional(list(string), [])
    container_name              = optional(string)
    container_metadata         = optional(map(string), {})
    container_access_type      = optional(string, "private")
  })
  nullable = false

  validation {
    condition     = var.create_storage_account ? (try(var.storage.name, "") != "" && can(regex("^[a-z0-9]{3,24}$", var.storage.name))) : true
    error_message = "Storage account name is required when create_storage_account is true and must be 3-24 characters, lowercase letters and numbers only."
  }
}

# ============================================================================
# Private Endpoint Module Configuration
# ============================================================================

variable "enable_private_link" {
  description = "Enable Private Endpoint for Storage Account. If true, private_endpoint configuration is required."
  type        = bool
  default     = true
}

variable "private_endpoint" {
  description = "Private Endpoint configuration for Zilliz Cloud connectivity. Only name is required, all other options use defaults. Required when enable_private_link is true."
  type = object({
    # Required: Name of the private endpoint
    name = string
    # Optional: Subnet name for private endpoint (default: "privatelink")
    subnet_name = optional(string, "privatelink")
  })
  default = null

  validation {
    condition     = var.enable_private_link ? var.private_endpoint != null : true
    error_message = "private_endpoint configuration is required when enable_private_link is true."
  }
}

# ============================================================================
# AKS Module Configuration
# ============================================================================

variable "aks" {
  description = "AKS Cluster configuration. Only node_pools is required, all other options use defaults."
  type = object({
    # Required: List of node pools for the AKS cluster
    node_pools = list(object({
      name                = string
      vm_size             = string
      node_count          = number
      min_count           = number
      max_count           = number
      enable_auto_scaling = bool
      os_disk_size_gb     = number
      os_disk_type        = string
      node_labels         = map(string)
      node_taints         = optional(list(string), [])
    }))
  })
  nullable = false
}

# ============================================================================
# AKS Agent Configuration
# ============================================================================

variable "acr_name" {
  description = "Azure Container Registry name (optional, defaults to config file value)"
  type        = string
  default     = ""
}

variable "acr_prefix" {
  description = "Azure Container Registry image prefix (optional, defaults to config file value)"
  type        = string
  default     = ""
}

variable "agent_tag" {
  description = "Agent image tag (optional, defaults to config file value)"
  type        = string
  default     = ""
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = ""
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

# ============================================================================
# Network Security Configuration
# ============================================================================

variable "network_security" {
  description = "Network security configuration"
  type = object({
    enable_public_support = optional(bool, false)
    allowed_subnets       = optional(list(string), ["milvus", "default"])
  })
  default = {}
}

variable "auth_token" {
  description = "Authentication token for agent communication"
  type        = string
}

variable "customer_acr" {
  description = "Customer ACR (Azure Container Registry) configuration. Full image path: {name}.azurecr.io/{prefix}/{image}:{tag}"
  type = object({
    name = string
    prefix = string
  })
  default = {
    name = ""
    prefix = ""
  }

  validation {
    condition     = var.customer_acr.name != "" && var.customer_acr.prefix != ""
    error_message = "customer_acr.name and customer_acr.prefix are required."
  }
}