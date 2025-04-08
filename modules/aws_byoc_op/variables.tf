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
    condition     = (length(var.vpc_id) == 0 || length(var.sg_id) == 0) ? length(var.vpc_cidr) > 0: length(var.vpc_cidr) == 0
    error_message = "variable vpc_cidr cannot be empty if vpc or security group is created and managed by terraform. Otherwise, leave it blank."
  }
}

// enable private link for the byoc project
variable "enable_private_link" {
  description = "Enable private link for the byoc project"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description  = "The ID of the VPC if VPC created and managed outside of this terraform"
  type         = string
  default      = ""
}

variable "private_subnets" {
  description  = "The private subnets of VPC if VPC created and managed outside of this terraform"
  type         = list(string)
  default      = []
  validation {
    condition = length(var.vpc_id) > 0 ? length(var.private_subnets) > 0 : length(var.private_subnets) == 0
    error_message = "You must specify private subnet ids if VPC is created externally to this terraform. Leave it blank if created and managed by this terraform."
  }
}

variable "sg_id" {
  description  = "The security group ID of VPC if VPC created and managed outside of this terraform"
  type         = string
  default      = ""
}

variable "eks_cluster_name" {
  description = "Specified name of EKS cluster"
  type        = string
  default     = ""
}

variable "bucket_id" {
  description = "ID of bucket if bucket is created and managed outside of this terraform"
  type        = string
  default     = ""
}

variable "storage_role_name" {
  description = "Specified name of the storage role for S3 access"
  type        = string
  default     = ""
}

variable "eks_addon_role_name" {
  description = "Specified name of the eks addon role for S3 access"
  type        = string
  default     = ""
}

variable "eks_role_name" {
  description = "Specified name of EKS cluster role"
  type        = string
  default     = ""
}

variable "maintenance_role_name" {
  description = "Specified name of the maintenance role for cluster administration"
  type        = string
  default     = ""
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