# The key remains customer-owned; Terraform only reads its public metadata.
data "azurerm_key_vault_key" "sse" {
  count        = local.customer_managed_key == null ? 0 : 1
  name         = local.customer_managed_key.key_name
  key_vault_id = local.customer_managed_key.key_vault_id
}

resource "azurerm_user_assigned_identity" "sse" {
  count               = local.customer_managed_key == null ? 0 : 1
  name                = "${var.storage_account_name}-sse"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "sse" {
  count                            = local.customer_managed_key == null ? 0 : 1
  scope                            = "${local.customer_managed_key.key_vault_id}/keys/${local.customer_managed_key.key_name}"
  role_definition_name             = "Key Vault Crypto Service Encryption User"
  principal_id                     = azurerm_user_assigned_identity.sse[0].principal_id
  skip_service_principal_aad_check = true
}
