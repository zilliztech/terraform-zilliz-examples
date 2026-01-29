data "azurerm_location" "current" {
  location = var.location
}

locals {
  # Example: var.vnet_cidr = "10.0.0.0/16"
  # 1. vnet_cidr_parts = ["10.0.0.0", "16"]
  vnet_cidr_parts = split("/", var.vnet_cidr)
  vnet_network    = local.vnet_cidr_parts[0] # "10.0.0.0"

  # 2. vnet_base_parts = ["10", "0", "0", "0"]
  vnet_base_parts = split(".", local.vnet_network)
  vnet_base_octets = [
    tonumber(local.vnet_base_parts[0]), # 10
    tonumber(local.vnet_base_parts[1]), # 0
    tonumber(local.vnet_base_parts[2]), # 0
    tonumber(local.vnet_base_parts[3])  # 0
  ]

  # 3. milvus subnet CIDR, e.g. "10.0.0.0/17"
  milvus_subnet_cidr      = cidrsubnet(var.vnet_cidr, 1, 0)
  # 4. privatelink subnet CIDR, e.g. "10.0.250.0/24"
  privatelink_subnet_cidr = "${local.vnet_base_octets[0]}.${local.vnet_base_octets[1]}.250.0/24"
}
