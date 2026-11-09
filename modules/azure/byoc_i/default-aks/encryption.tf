locals {
  customer_managed_key = var.enable_cmk_sse ? var.customer_managed_key : null
  disk_cmk_enabled     = local.customer_managed_key != null
}

data "azurerm_key_vault_key" "sse" {
  count        = local.disk_cmk_enabled ? 1 : 0
  name         = local.customer_managed_key.key_name
  key_vault_id = local.customer_managed_key.key_vault_id
}

# Separate identities keep Key Vault access out of the AKS control plane.
resource "azurerm_user_assigned_identity" "disk_sse" {
  count               = local.disk_cmk_enabled ? 1 : 0
  name                = "${var.cluster_name}-disk-sse"
  resource_group_name = var.resource_group_name
  location            = local.location
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "disk_key" {
  count                            = local.disk_cmk_enabled ? 1 : 0
  scope                            = "${local.customer_managed_key.key_vault_id}/keys/${local.customer_managed_key.key_name}"
  role_definition_name             = "Key Vault Crypto Service Encryption User"
  principal_id                     = azurerm_user_assigned_identity.disk_sse[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_disk_encryption_set" "sse" {
  count                     = local.disk_cmk_enabled ? 1 : 0
  name                      = "${var.cluster_name}-sse"
  resource_group_name       = var.resource_group_name
  location                  = local.location
  encryption_type           = "EncryptionAtRestWithCustomerKey"
  key_vault_key_id          = local.customer_managed_key.key_version == null ? data.azurerm_key_vault_key.sse[0].versionless_id : "${data.azurerm_key_vault_key.sse[0].versionless_id}/${local.customer_managed_key.key_version}"
  auto_key_rotation_enabled = local.customer_managed_key.key_version == null
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.disk_sse[0].id]
  }
  tags       = local.common_tags
  depends_on = [azurerm_role_assignment.disk_key]
}

# Pre-create the control-plane identity so DES access exists before AKS creation.
resource "azurerm_user_assigned_identity" "cmk_control_plane" {
  count               = local.disk_cmk_enabled ? 1 : 0
  name                = "${var.cluster_name}-control-plane"
  resource_group_name = var.resource_group_name
  location            = local.location
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "aks_des_reader" {
  count                            = local.disk_cmk_enabled ? 1 : 0
  scope                            = azurerm_disk_encryption_set.sse[0].id
  role_definition_name             = "Reader"
  principal_id                     = azurerm_user_assigned_identity.cmk_control_plane[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "cmk_aks_network_contributor" {
  count                            = local.disk_cmk_enabled ? 1 : 0
  scope                            = var.subnet_id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.cmk_control_plane[0].principal_id
  skip_service_principal_aad_check = true
}
