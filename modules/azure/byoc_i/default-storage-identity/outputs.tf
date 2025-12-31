output "storage_identity" {
  description = "The storage user assigned managed identity"
  value = {
    object_id   = azurerm_user_assigned_identity.storage_identity.id
    client_id   = azurerm_user_assigned_identity.storage_identity.client_id
    principal_id = azurerm_user_assigned_identity.storage_identity.principal_id
  }
}

output "instance_identities" {
  description = "List of instance user assigned managed identities"
  value = [
    for idx in sort([for k in local.instance_identities : k]) : {
      object_id   = azurerm_user_assigned_identity.instance_identity[idx].id
      client_id   = azurerm_user_assigned_identity.instance_identity[idx].client_id
      principal_id = azurerm_user_assigned_identity.instance_identity[idx].principal_id
    }
  ]
}

