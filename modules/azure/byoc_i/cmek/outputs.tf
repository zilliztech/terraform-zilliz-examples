output "identity" {
  description = "Dedicated CSE managed identity, or null when CSE is disabled."
  value = var.enabled ? {
    client_id    = azurerm_user_assigned_identity.cse[0].client_id
    principal_id = azurerm_user_assigned_identity.cse[0].principal_id
    resource_id  = azurerm_user_assigned_identity.cse[0].id
  } : null

  depends_on = [azurerm_federated_identity_credential.cse, azurerm_role_assignment.cse_key]
}

output "key_identifier" {
  description = "Existing versionless Key URL, or null when CSE is disabled."
  value       = var.enabled ? data.azurerm_key_vault_key.cse[0].versionless_id : null

  depends_on = [azurerm_federated_identity_credential.cse, azurerm_role_assignment.cse_key]
}
