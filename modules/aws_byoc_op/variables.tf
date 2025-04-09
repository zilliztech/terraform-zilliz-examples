variable "aws_region" {
  description = "The region in which the resources will be created"
  type        = string
  default     = "us-west-2"
  
}

// TODO: should be from web console
variable "vpc_cidr" {
  description = "The CIDR block for the customer VPC"
  type        = string
  nullable    = false

  validation {
    condition     = var.vpc_cidr != ""
    error_message = "variable vpc_cidr cannot be empty."
  }
}

// enable private link for the byoc project
variable "enable_private_link" {
  description = "Enable private link for the byoc project"
  type        = bool
  default     = false
}

variable "dataplane_id" {
  description = "The ID of the dataplane"
  type        = string
  nullable = false

  validation {
    condition     = can(regex("^zilliz-", var.dataplane_id))
    error_message = "Dataplane ID must start with 'zilliz-'"
  }
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
      instance_types = "m6id.4xlarge"
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

variable "agent_config" {
  description = "Configuration for the agent including server host, auth token, and k8s token"
  type = object({
    auth_token  = string
    tag         = string
  })

  nullable = false
}

variable "external_id" {
  description = "The external ID for the maintaince role"
  type        = string
  nullable    = false
}

variable "eks_enable_public_access" {
  description = "Enable public access to the EKS cluster"
  type        = bool
  default     = false
  
}