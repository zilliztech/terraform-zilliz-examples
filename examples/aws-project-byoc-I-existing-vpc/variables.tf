variable "aws_region" {
  description = "The region where zilliz operations will take place. Examples are us-east-1, us-west-2, etc."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the customer VPC"
  type        = string
  nullable    = false
}

variable "security_group_id" {
  description = "The ID of the security group for the customer VPC"
  type        = string
  nullable    = false
}

variable "subnet_ids" {
  description = "The IDs of the subnets for the customer VPC"
  type        = list(string)
  nullable    = false
}

variable "vpc_cidr" {
  description = "The CIDR block for the customer VPC"
  type        = string
  nullable    = false

  validation {
    condition     = var.vpc_cidr != ""
    error_message = "variable vpc_cidr cannot be empty."
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