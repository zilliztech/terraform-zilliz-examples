# Virtual Network Outputs
output "vnet_id" {
  description = "ID of the virtual network (created or customer provided)"
  value       = local.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = var.create_vnet ? module.vnet[0].vnet_name : null
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs (created or customer provided)"
  value       = local.subnet_ids
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to their address prefixes"
  value       = var.create_vnet ? module.vnet[0].subnet_address_prefixes : null
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = var.create_vnet ? module.vnet[0].nat_gateway_id : null
}

# Storage Account Outputs
output "storage_account_id" {
  description = "ID of the storage account (created or customer provided)"
  value       = local.storage_account_id
}

output "storage_account_name" {
  description = "Name of the storage account (created or customer provided)"
  value       = local.storage_account_name
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint URL"
  value       = var.create_storage_account ? module.storage_account[0].primary_blob_endpoint : null
}

output "storage_container_name" {
  description = "Name of the storage container"
  value       = local.storage_container_name
}

# Storage identities
output "storage_identities" {
  description = "Storage identities (list of {client_id, principal_id, resource_id})"
  value       = local.storage_identities
}

# Private Endpoint Outputs (only when enable_private_link is true)
# Note: This is for Zilliz Cloud private link, not Storage Account private endpoint
output "zilliz_private_endpoint_id" {
  description = "ID of the Zilliz Cloud private endpoint"
  value       = var.enable_private_link && local.private_endpoint_config != null ? module.zilliz_private_endpoint[0].private_endpoint_id : null
}

output "zilliz_private_endpoint_name" {
  description = "Name of the Zilliz Cloud private endpoint"
  value       = var.enable_private_link && local.private_endpoint_config != null ? module.zilliz_private_endpoint[0].private_endpoint_name : null
}

output "zilliz_private_endpoint_ip_address" {
  description = "IP address of the Zilliz Cloud private endpoint"
  value       = var.enable_private_link && local.private_endpoint_config != null ? module.zilliz_private_endpoint[0].private_endpoint_ip_address : null
  sensitive   = true
}

output "zilliz_private_dns_zone_id" {
  description = "ID of the private DNS zone for Zilliz Cloud"
  value       = var.enable_private_link && local.private_endpoint_config != null ? module.zilliz_private_endpoint[0].private_dns_zone_id : null
}

output "zilliz_private_dns_zone_name" {
  description = "Name of the private DNS zone for Zilliz Cloud"
  value       = var.enable_private_link && local.private_endpoint_config != null ? module.zilliz_private_endpoint[0].private_dns_zone_name : null
}

# AKS Outputs
output "aks_cluster_id" {
  description = "ID of the AKS cluster (created or customer provided)"
  value       = local.aks_cluster_id
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster (created or customer provided)"
  value       = local.aks_cluster_name
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = var.create_aks ? module.milvus_aks[0].cluster_fqdn : null
}

output "aks_cluster_private_fqdn" {
  description = "Private FQDN of the AKS cluster"
  value       = var.create_aks ? module.milvus_aks[0].cluster_private_fqdn : null
}

output "aks_kube_config" {
  description = "Kubernetes configuration for the AKS cluster"
  value       = var.create_aks ? module.milvus_aks[0].kube_config : null
  sensitive   = true
}

