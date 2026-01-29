output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.main.address_space
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value = {
    milvus      = azurerm_subnet.milvus.id
    privatelink = azurerm_subnet.privatelink.id
  }
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to their address prefixes"
  value = {
    milvus      = azurerm_subnet.milvus.address_prefixes
    privatelink = azurerm_subnet.privatelink.address_prefixes
  }
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = var.create_nat_gateway ? azurerm_nat_gateway.main[0].id : null
}

output "nat_gateway_public_ip_id" {
  description = "ID of the NAT Gateway public IP"
  value       = var.create_nat_gateway ? azurerm_public_ip.nat_gateway[0].id : null
}

output "network_security_group_id" {
  description = "ID of the Network Security Group"
  value       = azurerm_network_security_group.main.id
}
