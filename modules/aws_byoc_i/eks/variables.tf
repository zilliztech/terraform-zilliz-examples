
variable "prefix_name" {
  description = "Prefix name"
  type        = string
}

variable "region" {
  description = "Region"
  type        = string
  nullable    = false
}


variable "dataplane_id" {
  description = "Dataplane ID"
  type        = string
  nullable    = false
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}


variable "security_group_id" {
  description = "Security group ID"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
  default     = []
}

variable "customer_pod_subnet_ids" {
  description = "Pod subnet IDs"
  type        = list(string)
  default     = []
}

variable "eks_control_plane_subnet_ids" {
  description = "Subnet IDs for eks control plane; default to subnet_ids if not provided"
  type        = list(string)
  default     = []
}

variable "eks_enable_public_access" {
  description = "Enable public access"
  type        = bool
  default     = false
}

variable "external_id" {
  description = "External ID"
  type        = string
  nullable    = false
}

variable "enable_private_link" {
  description = "Enable private link for the byoc project"
  type        = bool
  default     = false
}

variable "agent_config" {
  description = "Configuration for the agent including server host, auth token, and k8s token"
  type = object({
    auth_token  = string
    tag         = string
  })

  nullable = false
}


variable "k8s_node_groups" {
  description = "Configuration for Kubernetes node groups"
  type = map(object({
    disk_size      = number
    min_size       = number
    max_size       = number
    desired_size   = number
    instance_types = string
    capacity_type  = string
  }))
  
  default = {
    core = {
      disk_size      = 100
      min_size       = 1
      max_size       = 50
      desired_size   = 1
      instance_types = "m6i.2xlarge"
      capacity_type  = "SPOT"
    }
    index = {
      disk_size      = 100
      min_size       = 0
      max_size       = 100
      desired_size   = 0
      instance_types = "m6i.2xlarge"
      capacity_type  = "SPOT"
    }
    search = {
      disk_size      = 100
      min_size       = 0
      max_size       = 100
      desired_size   = 0
      instance_types = "m6i.2xlarge"
      capacity_type  = "SPOT"
    }
    fundamental = {
      disk_size      = 50
      min_size       = 0
      max_size       = 6
      desired_size   = 0
      instance_types = "m6i.2xlarge"
      capacity_type  = "SPOT"
    }
  }
  
  validation {
    condition = alltrue([
      for k, v in var.k8s_node_groups : 
        v.disk_size > 0 && 
        v.min_size >= 0 && 
        v.max_size > 0 && 
        v.desired_size >= 0 && 
        v.desired_size <= v.max_size &&
        contains(["ON_DEMAND", "SPOT"], v.capacity_type)
    ])
    error_message = "Invalid node group configuration. Ensure disk sizes are positive, sizes are valid, and capacity_type is either ON_DEMAND or SPOT."
  }
}

variable "s3_bucket_id" {
  description = "S3 bucket ID"
  type        = string
  default     = ""
}

variable "customer_eks_cluster_name" {
  description = "The name of the customer EKS cluster"
  type        = string
  default     = ""
}

variable "customer_storage_role_name" {
  description = "The name of the customer storage role for S3 access"
  type        = string
  default     = ""
}

variable "customer_eks_addon_role_name" {
  description = "The name of the customer EKS addon role for S3 access"
  type        = string
  default     = ""
}

variable "customer_eks_role_name" {
  description = "The name of the customer EKS cluster role"
  type        = string
  default     = ""
}

variable "customer_maintenance_role_name" {
  description = "The name of the customer maintenance role for cluster administration"
  type        = string
  default     = ""
}

variable "custom_tags" {
  description = "Custom tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "customer_ecr" {
  description = "Customer ECR configuration containing account ID, region, and prefix"
  type = object({
    ecr_account_id = string
    ecr_region     = string
    ecr_prefix     = string
    }
  )
  validation {
    condition     = var.customer_ecr.ecr_prefix != "" && var.customer_ecr.ecr_account_id != ""
    error_message = "ECR prefix and account ID cannot be empty. If ecr_region is empty, var.region will be used as the default."
  }

  default = {
    ecr_account_id = "965570967084"
    ecr_region     = ""
    ecr_prefix     = "zilliz-byoc"
  }
}

variable "booter" {
  description = "Booter configuration including account ID, region, prefix, image, and tag"
  type = object({
    account_id = optional(string, "")
    region     = optional(string, "")
    prefix     = optional(string, "")
    image      = optional(string, "")
    tag        = optional(string, "")
  })
  default = {
    account_id = ""
    region     = ""
    prefix     = ""
    image      = ""
    tag        = ""
  }
}