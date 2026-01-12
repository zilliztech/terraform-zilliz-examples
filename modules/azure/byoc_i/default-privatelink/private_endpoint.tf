# Private DNS Zone
resource "azurerm_private_dns_zone" "zone" {
  name                = local.dns_zone_name
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

# Private DNS Zone Virtual Network Link
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "${local.dns_zone_name}-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.zone.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false

  tags = local.common_tags
}

# DNS A Record for root domain (@) pointing to private endpoint
resource "azurerm_private_dns_a_record" "root" {
  name                = "@"
  zone_name           = azurerm_private_dns_zone.zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.main.private_service_connection[0].private_ip_address]

  tags = local.common_tags
}

# Azure Private Endpoint
resource "azurerm_private_endpoint" "main" {
  name                = var.private_endpoint_name
  location            = local.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  # Private Service Connection
  private_service_connection {
    name                              = "${var.private_endpoint_name}-connection"
    is_manual_connection              = true
    private_connection_resource_alias = local.zilliz_byoc_privatelink_resource_alias
    subresource_names                 = []
    request_message                   = "Please approve the private endpoint connection request"
  }

  # Private DNS Zone Group (automatically manages DNS records)
  private_dns_zone_group {
    name                 = "${var.private_endpoint_name}-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.zone.id]
  }

  tags = local.common_tags
}


