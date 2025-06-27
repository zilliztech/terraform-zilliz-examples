variable "aws_region" {
  description = "The region where zilliz operations will take place. Examples are us-east-1, us-west-2, etc."
  type        = string
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

// enable private link for the byoc project
variable "enable_private_link" {
  description = "Enable private link for the byoc project"
  type        = bool
  default     = false
}

variable "instances" {
  description = "Instance configuration for the BYOC project"
  type = object({
    core = object({
      vm    = string
      count = number
    })
    fundamental = object({
      vm        = string
      min_count = number
      max_count = number
    })
    search = object({
      vm        = string
      min_count = number
      max_count = number
    })
    index = object({
      vm        = string
      min_count = number
      max_count = number
    })
    auto_scaling = bool
    arch         = string
  })
  default = {
    core = {
      vm    = "m6i.2xlarge"
      count = 3
    }
    fundamental = {
      vm        = "m6i.2xlarge"
      min_count = 1
      max_count = 2
    }
    search = {
      vm        = "m6id.4xlarge"
      min_count = 1
      max_count = 2
    }
    index = {
      vm        = "m6i.2xlarge"
      min_count = 1
      max_count = 2
    }
    auto_scaling = true
    arch         = "X86"
  }
}