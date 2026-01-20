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
  description = "Configuration for Kubernetes node groups (similar to AWS EKS k8s_node_groups). Supports any node pool names."
  type = map(object({
    vm_size             = string
    min_size            = number
    max_size            = number
    desired_size        = number
    os_disk_size_gb     = number
    enable_auto_scaling = optional(bool, true)
  }))

  default = {}

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
