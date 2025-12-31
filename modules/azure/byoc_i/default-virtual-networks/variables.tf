variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "location" {
  description = "Azure region where the virtual network will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR block for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "create_nat_gateway" {
  description = "Whether to create a NAT Gateway"
  type        = bool
  default     = false
}

variable "nat_gateway_name" {
  description = "Name of the NAT Gateway"
  type        = string
  default     = "nat-gateway"
}

variable "nat_gateway_sku" {
  description = "SKU for the NAT Gateway"
  type        = string
  default     = "Standard"
}

variable "custom_tags" {
  description = "Custom tags to apply to all resources (merged with Vendor=zilliz-byoc tag)"
  type        = map(string)
  default     = {}
}
