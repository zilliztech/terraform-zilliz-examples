variable "region" {
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

variable "ExternalId" {
  description = "External identifier to use when assuming the role. To avoid the confused deputy problem."
  type        = string
}

variable "enable_private_link" {
  description = "Enable private link for the byoc project"
  type        = bool
  default     = false
}