output "storage_account_id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "primary_access_key" {
  description = "The primary access key for the storage account"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "The secondary access key for the storage account"
  value       = azurerm_storage_account.main.secondary_access_key
  sensitive   = true
}

output "primary_blob_endpoint" {
  description = "The endpoint URL for blob storage in the primary location"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "secondary_blob_endpoint" {
  description = "The endpoint URL for blob storage in the secondary location"
  value       = azurerm_storage_account.main.secondary_blob_endpoint
}

output "primary_blob_host" {
  description = "The hostname with port if applicable for blob storage in the primary location"
  value       = azurerm_storage_account.main.primary_blob_host
}

output "secondary_blob_host" {
  description = "The hostname with port if applicable for blob storage in the secondary location"
  value       = azurerm_storage_account.main.secondary_blob_host
}

# Container outputs
output "byoc_data_container_name" {
  description = "The name of the BYOC data container"
  value       = azurerm_storage_container.zilliz_container.name
}

output "byoc_data_container_id" {
  description = "The ID of the BYOC data container"
  value       = azurerm_storage_container.zilliz_container.id
}
