
variable "enable_private_link" {
  description = "Enable private link"
  type        = bool
  default     = false
}

variable "region" {
  description = "Region"
  type        = string
}


variable "dataplane_id" {
  description = "Dataplane ID"
  type        = string
}


variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}


variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
}
