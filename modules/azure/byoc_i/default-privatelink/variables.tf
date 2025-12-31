variable "private_endpoint_name" {
  description = "Name of the private endpoint"
  type        = string
}

variable "location" {
  description = "Azure region where the private endpoint will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet where the private endpoint will be created"
  type        = string
}

variable "vnet_id" {
  description = "ID of the virtual network to link DNS zones to"
  type        = string
}

variable "custom_tags" {
  description = "Custom tags to apply to all resources (merged with Vendor=zilliz-byoc tag)"
  type        = map(string)
  default     = {}
}
