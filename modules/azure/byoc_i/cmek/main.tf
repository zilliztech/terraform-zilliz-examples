locals {
  key_parts   = try(regex("^https://([a-zA-Z0-9-]+)\\.vault\\.azure\\.net/keys/([a-zA-Z0-9-]+)$", var.key_identifier), ["", ""])
  vault_parts = try(regex("(?i)^/subscriptions/([^/]+)/resourceGroups/([^/]+)/providers/Microsoft\\.KeyVault/vaults/([^/]+)$", var.key_vault_id), ["", "", ""])
}

data "azurerm_client_config" "current" {
  count = var.enabled ? 1 : 0
}

resource "terraform_data" "validate" {
  count = var.enabled ? 1 : 0

  input = var.enabled

  lifecycle {
    precondition {
      condition     = !var.enabled || (local.key_parts[0] != "" && local.vault_parts[2] != "" && lower(local.key_parts[0]) == lower(local.vault_parts[2]))
      error_message = "When CSE is enabled, provide a versionless public Key URL and the ARM ID of its Key Vault. The vault names must match."
    }
    precondition {
      condition     = var.enabled ? lower(local.vault_parts[0]) == lower(data.azurerm_client_config.current[0].subscription_id) : true
      error_message = "The existing CSE Key Vault must be in the Azure provider's deployment subscription. Cross-subscription CSE is not supported by this example."
    }
  }
}

data "azurerm_key_vault" "cse" {
  count = var.enabled ? 1 : 0

  name                = local.vault_parts[2] != "" ? local.vault_parts[2] : "invalid"
  resource_group_name = local.vault_parts[1] != "" ? local.vault_parts[1] : "invalid"

  depends_on = [terraform_data.validate]

  lifecycle {
    postcondition {
      condition     = self.enable_rbac_authorization == true
      error_message = "The existing CSE Key Vault must use Azure RBAC authorization. Access-policy Vaults are not supported."
    }
  }
}

data "azurerm_key_vault_key" "cse" {
  count = var.enabled ? 1 : 0

  name         = local.key_parts[1] != "" ? local.key_parts[1] : "invalid"
  key_vault_id = var.key_vault_id

  depends_on = [data.azurerm_key_vault.cse]

  lifecycle {
    postcondition {
      condition     = self.key_type == "oct-HSM" && contains(self.key_opts, "encrypt") && contains(self.key_opts, "decrypt")
      error_message = "Azure CSE requires an existing AES (oct-HSM) Key with encrypt and decrypt operations enabled. RSA, EC and wrap-only Keys are not supported."
    }
  }
}

resource "azurerm_user_assigned_identity" "cse" {
  count = var.enabled ? 1 : 0

  name                = "${var.name_prefix}-cse"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  depends_on = [data.azurerm_key_vault_key.cse]
}

resource "azurerm_federated_identity_credential" "cse" {
  count = var.enabled ? 1 : 0

  name                = "milvus-tool-cse-federation"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.cse[0].id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  subject             = "system:serviceaccount:milvus-tool:milvus-bucket"
}

resource "azurerm_role_assignment" "cse_key" {
  count = var.enabled ? 1 : 0

  scope                            = data.azurerm_key_vault_key.cse[0].resource_versionless_id
  role_definition_name             = "Key Vault Crypto User"
  principal_id                     = azurerm_user_assigned_identity.cse[0].principal_id
  skip_service_principal_aad_check = true
}
