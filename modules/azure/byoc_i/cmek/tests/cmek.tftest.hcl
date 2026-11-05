mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "11111111-1111-1111-1111-111111111111"
    }
  }
  mock_data "azurerm_key_vault" {
    defaults = {
      enable_rbac_authorization = true
    }
  }
  mock_data "azurerm_key_vault_key" {
    defaults = {
      key_type                = "oct-HSM"
      key_opts                = ["encrypt", "decrypt"]
      versionless_id          = "https://customer-vault.vault.azure.net/keys/customer-key"
      resource_versionless_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/key-rg/providers/Microsoft.KeyVault/vaults/customer-vault/keys/customer-key"
    }
  }
  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/dataplane-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test-cse"
      principal_id = "22222222-2222-2222-2222-222222222222"
      client_id    = "33333333-3333-3333-3333-333333333333"
    }
  }
}

variables {
  name_prefix         = "test"
  location            = "westus3"
  resource_group_name = "dataplane-rg"
  aks_oidc_issuer_url = "https://westus3.oic.prod-aks.azure.com/tenant/cluster/"
  key_identifier      = "https://customer-vault.vault.azure.net/keys/customer-key"
  key_vault_id        = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/key-rg/providers/Microsoft.KeyVault/vaults/customer-vault"
}

run "disabled_has_no_cloud_resources" {
  command = plan
  variables {
    key_identifier = ""
    key_vault_id   = ""
  }

  assert {
    condition     = length(terraform_data.validate) == 0 && length(azurerm_user_assigned_identity.cse) == 0 && length(azurerm_federated_identity_credential.cse) == 0 && length(azurerm_role_assignment.cse_key) == 0 && length(data.azurerm_key_vault_key.cse) == 0 && output.identity == null && output.key_identifier == null
    error_message = "CSE must default to disabled without validation state, Azure reads, identities, federation or IAM changes."
  }
}

run "existing_aes_key_has_dedicated_identity_and_key_scoped_grant" {
  command = apply
  variables { enabled = true }

  assert {
    condition     = azurerm_user_assigned_identity.cse[0].name == "test-cse" && azurerm_user_assigned_identity.cse[0].resource_group_name == "dataplane-rg"
    error_message = "CSE must create its own identity in the DataPlane resource group."
  }
  assert {
    condition     = azurerm_federated_identity_credential.cse[0].parent_id == output.identity.resource_id && azurerm_federated_identity_credential.cse[0].subject == "system:serviceaccount:milvus-tool:milvus-bucket" && length(azurerm_federated_identity_credential.cse[0].audience) == 1 && azurerm_federated_identity_credential.cse[0].audience[0] == "api://AzureADTokenExchange" && azurerm_federated_identity_credential.cse[0].issuer == var.aks_oidc_issuer_url
    error_message = "Only the DataPlane milvus-tool workload federation must be created for the CSE identity."
  }
  assert {
    condition     = azurerm_role_assignment.cse_key[0].scope == "${var.key_vault_id}/keys/customer-key" && azurerm_role_assignment.cse_key[0].principal_id == output.identity.principal_id && azurerm_role_assignment.cse_key[0].role_definition_name == "Key Vault Crypto User" && output.key_identifier == var.key_identifier
    error_message = "The existing AES Key in another resource group must receive a Key-scoped encrypt/decrypt role for the dedicated identity."
  }
}

run "versioned_key_identifier_is_rejected" {
  command = plan
  variables {
    enabled        = true
    key_identifier = "https://customer-vault.vault.azure.net/keys/customer-key/version"
  }
  expect_failures = [terraform_data.validate]
}

run "missing_key_is_rejected_when_enabled" {
  command = plan
  variables {
    enabled        = true
    key_identifier = ""
  }
  expect_failures = [terraform_data.validate]
}

run "mismatched_vault_is_rejected" {
  command = plan
  variables {
    enabled        = true
    key_identifier = "https://other-vault.vault.azure.net/keys/customer-key"
  }
  expect_failures = [terraform_data.validate]
}

run "rsa_key_is_rejected" {
  command = plan
  variables { enabled = true }
  override_data {
    target = data.azurerm_key_vault_key.cse[0]
    values = {
      key_type = "RSA"
      key_opts = ["encrypt", "decrypt"]
    }
  }
  expect_failures = [data.azurerm_key_vault_key.cse]
}

run "wrap_only_key_is_rejected" {
  command = plan
  variables { enabled = true }
  override_data {
    target = data.azurerm_key_vault_key.cse[0]
    values = {
      key_type = "oct-HSM"
      key_opts = ["wrapKey", "unwrapKey"]
    }
  }
  expect_failures = [data.azurerm_key_vault_key.cse]
}

run "cross_subscription_key_is_rejected" {
  command = plan
  variables {
    enabled      = true
    key_vault_id = "/subscriptions/99999999-9999-9999-9999-999999999999/resourceGroups/key-rg/providers/Microsoft.KeyVault/vaults/customer-vault"
  }
  expect_failures = [terraform_data.validate]
}

run "access_policy_vault_is_rejected" {
  command = plan
  variables { enabled = true }
  override_data {
    target = data.azurerm_key_vault.cse[0]
    values = { enable_rbac_authorization = false }
  }
  expect_failures = [data.azurerm_key_vault.cse]
}
