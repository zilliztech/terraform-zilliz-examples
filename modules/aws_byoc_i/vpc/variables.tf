
variable "prefix_name" {
  description = "Prefix name"
  type        = string
}

variable "dataplane_id" {
  description = "Unique identifier for the dataplane"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "region" {
  description = "The region in which the resources will be created"
  type        = string
  
}

variable "custom_tags" {
  description = "Custom tags to apply to resources"
  type        = map(string)
  default     = {}
}


