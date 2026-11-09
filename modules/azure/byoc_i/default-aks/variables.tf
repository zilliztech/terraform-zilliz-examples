variable "prefix_name" {
  description = "Prefix name for resource naming (similar to AWS EKS pattern, e.g., 'zilliz-byoc')"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region where the AKS cluster will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet where the AKS cluster will be deployed"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster (uses latest if not specified)"
  type        = string
  default     = null
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.255.0.0/16"
}

# Default Node Pool Configuration
variable "default_node_pool" {
  description = "Configuration for the default node pool"
  type = object({
    vm_size             = string
    node_count          = number
    min_count           = number
    max_count           = number
    enable_auto_scaling = bool
  })
  default = {
    vm_size             = "Standard_D4as_v5"
    node_count          = 1
    min_count           = 1
    max_count           = 5
    enable_auto_scaling = true
  }
}

# Additional Node Pools Configuration
# Similar to AWS EKS k8s_node_groups pattern - supports dynamic node pools
variable "k8s_node_groups" {
  description = "Configuration for Kubernetes node groups. Must contain keys: core, search, index, fundamental."
  type = map(object({
    vm_size             = string
    min_size            = number
    max_size            = number
    desired_size        = number
    os_disk_size_gb     = number
    enable_auto_scaling = optional(bool, true)
  }))

  validation {
    condition     = length(setsubtract(["core", "search", "index", "fundamental"], keys(var.k8s_node_groups))) == 0
    error_message = "k8s_node_groups must contain all required keys: core, search, index, fundamental."
  }

  validation {
    condition = alltrue([
      for k, v in var.k8s_node_groups :
      v.vm_size != "" &&
      v.min_size >= 0 &&
      v.max_size > 0 &&
      v.desired_size >= 0 &&
      v.desired_size <= v.max_size &&
      v.os_disk_size_gb > 0
    ])
    error_message = "Invalid node group configuration. Ensure vm_size is set, sizes are valid, and os_disk_size_gb is positive."
  }
}


variable "custom_tags" {
  description = "Custom tags to apply to all resources (merged with Vendor=zilliz-byoc tag)"
  type        = map(string)
  default     = {}
}

variable "vnet_id" {
  description = "Resource ID of the virtual network (required for maintenance identity role assignments)"
  type        = string
}

variable "instance_storage_identity_ids" {
  description = "List of resource IDs of all instance storage identities for federated credential management"
  type        = list(string)
  default     = []
}

variable "storage_identity_id" {
  description = "Resource ID of the storage identity"
  type        = string
  default     = ""
}

variable "agent_tag" {
  description = "Agent image tag"
  type        = string
}

variable "tunnel_client_tag" {
  description = "Tunnel client image tag or full reference; empty keeps the legacy agent deployment. Requires a matching split cloud-agent image when set."
  type        = string
  default     = ""
  nullable    = false
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = ""
}

variable "dataplane_id" {
  description = "Dataplane ID"
  type        = string
  default     = ""
}

variable "enable_private_endpoint" {
  description = "Whether to enable private endpoint for the AKS cluster"
  type        = bool
  default     = false
}

variable "auth_token" {
  description = "Authentication token for agent communication"
  type        = string
}

variable "customer_managed_key" {
  description = "Existing same-tenant RBAC Key Vault key for AKS OS disk SSE (including Ephemeral OS disks). Null uses Microsoft-managed keys; omit key_version for automatic rotation."
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
