resource "azurerm_subnet" "milvus" {
  name                 = "milvus"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.milvus_subnet_cidr]

  service_endpoints = ["Microsoft.Storage"]
  private_link_service_network_policies_enabled = true
  private_endpoint_network_policies             = "Enabled"
}

resource "azurerm_subnet" "privatelink" {
  name                 = "privatelink"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.privatelink_subnet_cidr]

  service_endpoints = ["Microsoft.Storage"]
  private_link_service_network_policies_enabled = true
  private_endpoint_network_policies             = "Enabled"
}

resource "azurerm_subnet_nat_gateway_association" "milvus" {
  count = var.create_nat_gateway ? 1 : 0

  subnet_id      = azurerm_subnet.milvus.id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.vnet_name}-nsg"
  location            = local.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowVNetInBound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.vnet_cidr
    destination_address_prefix = var.vnet_cidr
    description                = "Allow all inbound traffic within VNet"
  }

  security_rule {
    name                       = "AllowVNetOutBound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.vnet_cidr
    destination_address_prefix = var.vnet_cidr
    description                = "Allow all outbound traffic within VNet"
  }

  security_rule {
    name                       = "AllowHTTPSOutBound"
    priority                   = 1100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow outbound HTTPS traffic to internet"
  }

  tags = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "milvus" {
  subnet_id                 = azurerm_subnet.milvus.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_subnet_network_security_group_association" "privatelink" {
  subnet_id                 = azurerm_subnet.privatelink.id
  network_security_group_id = azurerm_network_security_group.main.id
}