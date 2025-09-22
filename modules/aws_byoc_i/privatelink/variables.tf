variable "prefix_name" {
  description = "Prefix name"
  type        = string
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

variable "create_security_group" {
  description = "Whether to create a new security group for the private link endpoint"
  type        = bool
  default     = false
}

variable "security_group_name" {
  description = "The name of the security group for the private link, if create_security_group is true"
  type        = string
  default     = ""
}

variable "custom_tags" {
  description = "Custom tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_private_hosted_zone" {
  description = "Enable private hosted zone"
  type        = bool
  default     = true
}
