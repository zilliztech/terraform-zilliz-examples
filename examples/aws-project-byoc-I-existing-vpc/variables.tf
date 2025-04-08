variable "aws_region" {
  description = "The region where zilliz operations will take place. Examples are us-east-1, us-west-2, etc."
  type        = string
}

variable "customer_vpc_id" {
  description = "The ID of the customer VPC"
  type        = string
  nullable    = false

  validation {
    condition     = var.customer_vpc_id != ""
    error_message = "variable customer_vpc_id cannot be empty."
  }
}

variable "customer_security_group_id" {
  description = "The ID of the security group for the customer VPC"
  type        = string
  nullable    = false

  validation {
    condition     = var.customer_security_group_id != ""
    error_message = "variable customer_security_group_id cannot be empty."
  }
}

variable "customer_subnet_ids" {
  description = "The IDs of the subnets for the customer VPC"
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.customer_subnet_ids) > 0
    error_message = "variable customer_subnet_ids cannot be empty."
  }
}

variable "customer_vpc_cidr" {
  description = "The CIDR block for the customer VPC"
  type        = string
  nullable    = false

  validation {
    condition     = var.customer_vpc_cidr != ""
    error_message = "variable customer_vpc_cidr cannot be empty."
  }
}

variable "name" {
  description = "The name of the byoc project"
  type        = string
  nullable    = false

  validation {
    condition     = var.name != ""
    error_message = "variable name cannot be empty."
  }
}

variable "enable_private_link" {
  description = "Enable private link for the byoc project"
  type        = bool
  default     = false
}



variable "core_instance_type" {
  description = "Instance type for core VM"
  type        = string
  default     = "m6i.2xlarge"
}

variable "fundamental_instance_type" {
  description = "Instance type for fundamental VM"
  type        = string
  default     = "m6i.2xlarge"
}

variable "search_instance_type" {
  description = "Instance type for search VM"
  type        = string
  default     = "m6id.2xlarge"
}

variable "customer_ecr" {
  description = "Customer ECR"
  type        = string
  default     = ""
}

variable "customer_bucket_id" {
  description = "The ID of customer bucket"
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