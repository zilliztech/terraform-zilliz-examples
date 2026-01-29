output "private_endpoint_id" {
  description = "ID of the private endpoint"
  value       = azurerm_private_endpoint.main.id
}

output "private_endpoint_name" {
  description = "Name of the private endpoint"
  value       = azurerm_private_endpoint.main.name
}

output "private_endpoint_network_interface_id" {
  description = "ID of the network interface associated with the private endpoint"
  value       = azurerm_private_endpoint.main.network_interface[0].id
}

output "private_dns_zone_id" {
  description = "ID of the created private DNS zone"
  value       = azurerm_private_dns_zone.zone.id
}

output "private_dns_zone_name" {
  description = "Name of the created private DNS zone"
  value       = azurerm_private_dns_zone.zone.name
}

output "private_dns_zone_vnet_link_id" {
  description = "ID of the DNS zone virtual network link"
  value       = azurerm_private_dns_zone_virtual_network_link.vnet_link.id
}

output "private_endpoint_ip_address" {
  description = "IP address of the private endpoint"
  value       = azurerm_private_endpoint.main.private_service_connection[0].private_ip_address
  sensitive   = true
}