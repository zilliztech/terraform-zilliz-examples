variable "project_id" {
  description = "The ID of the byoc project"
  type        = string
  nullable    = false
}


variable "dataplane_id" {
  description = "The ID of the data plane"
  type        = string
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

variable "enable_private_link" {
  description = "Enable private link for the byoc project"
  type        = bool
  default     = true
}

