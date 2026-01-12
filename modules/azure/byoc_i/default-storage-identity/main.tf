# Storage Identity - User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "storage_identity" {
  name                = "${local.storage_identity_name}-default"
  location            = local.location
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

# Role Assignment: Storage Blob Data Contributor on container
# This allows the storage identity to read/write blobs in the container
resource "azurerm_role_assignment" "container_bind" {
  scope                = var.storage_container_scope
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.storage_identity.principal_id

  description = "Allow storage identity to access storage container"
}
# Instance Identities - User Assigned Managed Identities
resource "azurerm_user_assigned_identity" "instance_identity" {
  for_each = local.instance_identities

  name                = "${local.storage_identity_name}-${each.value}"
  location            = local.location
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

# Role Assignment: Storage Blob Data Contributor on container for instance identities
resource "azurerm_role_assignment" "container_bind_instance" {
  for_each = local.instance_identities

  scope                = var.storage_container_scope
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.instance_identity[each.value].principal_id

  description = "Allow instance identity ${each.value} to access storage container"
}



