# NAT Gateway
resource "azurerm_nat_gateway" "main" {
  count = var.create_nat_gateway ? 1 : 0

  name                = var.nat_gateway_name
  location            = local.location
  resource_group_name = var.resource_group_name
  sku_name            = var.nat_gateway_sku

  tags = local.common_tags
}

# Public IP for NAT Gateway
resource "azurerm_public_ip" "nat_gateway" {
  count = var.create_nat_gateway ? 1 : 0

  name                = "${var.nat_gateway_name}-pip"
  location            = local.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

# Associate Public IP with NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "main" {
  count = var.create_nat_gateway ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.main[0].id
  public_ip_address_id = azurerm_public_ip.nat_gateway[0].id
}
