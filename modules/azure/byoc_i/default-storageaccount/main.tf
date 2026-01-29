# Microsoft.Storage/storageAccounts
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind

  # ARM template properties mapping
  min_tls_version                 = var.minimum_tls_version
  allow_nested_items_to_be_public = var.allow_blob_public_access
  shared_access_key_enabled       = var.allow_shared_key_access
  public_network_access_enabled   = var.public_network_access_enabled
  cross_tenant_replication_enabled = var.allow_cross_tenant_replication
  infrastructure_encryption_enabled = var.require_infrastructure_encryption
  access_tier                     = var.access_tier
  
  # Additional properties to match Azure configuration
  https_traffic_only_enabled      = true
  large_file_share_enabled        = true
  local_user_enabled              = true
  queue_encryption_key_type       = "Service"
  table_encryption_key_type       = "Service"

  # Network access rules - ARM template networkAcls
  network_rules {
    default_action             = var.network_default_action
    bypass                     = var.network_bypass
    ip_rules                   = var.ip_rules
    virtual_network_subnet_ids = var.virtual_network_subnet_ids
  }

  # Blob properties - hardcoded values to match Azure configuration
  blob_properties {
    change_feed_enabled           = false
    last_access_time_enabled      = false
    versioning_enabled            = false
    
    container_delete_retention_policy {
      days = 7
    }
    
    delete_retention_policy {
      days                     = 7
      permanent_delete_enabled = false
    }
  }
  
  # Share properties - hardcoded values to match Azure configuration
  share_properties {
    retention_policy {
      days = 7
    }
  }

  tags = local.common_tags
}

# Microsoft.Storage/storageAccounts/blobServices/containers
resource "azurerm_storage_container" "zilliz_container" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = var.container_access_type

  # ARM template container properties
  metadata = var.container_metadata
}
