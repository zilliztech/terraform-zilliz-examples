# ============================================================================
# Common Variables
# ============================================================================

variable "name" {
  description = "The name of the BYOC project (used for resource naming)"
  type        = string
  nullable    = false

  validation {
    condition     = var.name != ""
    error_message = "variable name cannot be empty."
  }
}

variable "location" {
  description = "Azure region where resources will be created (e.g., 'East US', 'West Europe')"
  type        = string
  nullable    = false

  validation {
    condition     = var.location != ""
    error_message = "variable location cannot be empty."
  }
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  nullable    = false

  validation {
    condition     = var.resource_group_name != ""
    error_message = "variable resource_group_name cannot be empty."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Resource Creation Flags
# ============================================================================

variable "create_vnet" {
  description = "Whether to create a new VNet. If false, customer_vnet_id must be provided."
  type        = bool
  default     = true
}

variable "create_storage_account" {
  description = "Whether to create a new Storage Account. If false, customer_storage_account_id must be provided."
  type        = bool
  default     = true
}

variable "create_storage_identity" {
  description = "Whether to create a new Storage Identity. If false, customer_storage_identity_id must be provided."
  type        = bool
  default     = true
}

variable "create_aks" {
  description = "Whether to create a new AKS cluster. If false, customer_aks_cluster_id must be provided."
  type        = bool
  default     = true
}

# ============================================================================
# Customer Provided Resources
# ============================================================================

variable "customer_vnet_id" {
  description = "ID of existing VNet to use. Required when create_vnet is false."
  type        = string
  default     = ""

  validation {
    condition     = var.create_vnet || var.customer_vnet_id != ""
    error_message = "customer_vnet_id is required when create_vnet is false."
  }
}

variable "customer_subnet_ids" {
  description = "Map of subnet names to their IDs for existing VNet. Required when create_vnet is false. Format: { milvus = \"subnet-id\", privatelink = \"subnet-id\" }"
  type        = map(string)
  default     = {}

  validation {
    condition     = var.create_vnet || (length(var.customer_subnet_ids) > 0 && contains(keys(var.customer_subnet_ids), "milvus"))
    error_message = "customer_subnet_ids must include at least 'milvus' subnet when create_vnet is false."
  }
}

variable "customer_storage_account_id" {
  description = "ID of existing Storage Account to use. Required when create_storage_account is false."
  type        = string
  default     = ""

  validation {
    condition     = var.create_storage_account || var.customer_storage_account_id != ""
    error_message = "customer_storage_account_id is required when create_storage_account is false."
  }
}

variable "customer_storage_account_name" {
  description = "Name of existing Storage Account. Required when create_storage_account is false."
  type        = string
  default     = ""

  validation {
    condition     = var.create_storage_account || var.customer_storage_account_name != ""
    error_message = "customer_storage_account_name is required when create_storage_account is false."
  }
}

variable "customer_storage_container_name" {
  description = "Name of existing storage container. Required when create_storage_account is false."
  type        = string
  default     = ""
}

variable "customer_storage_identity_id" {
  description = "ID of existing Storage Identity (User Assigned Managed Identity) to use. Required when create_storage_identity is false."
  type        = string
  default     = ""

  validation {
    condition     = var.create_storage_identity || var.customer_storage_identity_id != ""
    error_message = "customer_storage_identity_id is required when create_storage_identity is false."
  }
}

variable "customer_storage_identity_client_id" {
  description = "Client ID of existing Storage Identity. Required when create_storage_identity is false."
  type        = string
  default     = ""

  validation {
    condition     = var.create_storage_identity || var.customer_storage_identity_client_id != ""
    error_message = "customer_storage_identity_client_id is required when create_storage_identity is false."
  }
}

variable "customer_storage_identity_principal_id" {
  description = "Principal ID of existing Storage Identity. Required when create_storage_identity is false."
  type        = string
  default     = ""

  validation {
    condition     = var.create_storage_identity || var.customer_storage_identity_principal_id != ""
    error_message = "customer_storage_identity_principal_id is required when create_storage_identity is false."
  }
}

variable "customer_aks_cluster_id" {
  description = "ID of existing AKS cluster to use. Required when create_aks is false."
  type        = string
  default     = ""

  validation {
    condition     = var.create_aks || var.customer_aks_cluster_id != ""
    error_message = "customer_aks_cluster_id is required when create_aks is false."
  }
}

variable "customer_aks_cluster_name" {
  description = "Name of existing AKS cluster. Required when create_aks is false."
  type        = string
  default     = ""

  validation {
    condition     = var.create_aks || var.customer_aks_cluster_name != ""
    error_message = "customer_aks_cluster_name is required when create_aks is false."
  }
}

# ============================================================================
# VNet Module Configuration
# ============================================================================

variable "vnet" {
  description = "Virtual Network configuration. CIDR is required when create_vnet is true, all other options use defaults."
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

variable "dataplane_id" {
  description = "Dataplane ID"
  type        = string
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