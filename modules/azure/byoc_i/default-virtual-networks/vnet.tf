# Azure Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  location            = local.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]

  tags = local.common_tags
}
