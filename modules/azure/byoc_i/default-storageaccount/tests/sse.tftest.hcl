mock_provider "azurerm" {
  mock_data "azurerm_key_vault_key" {
    defaults = {
      versionless_id = "https://byoc-test.vault.azure.net/keys/storage-key"
    }
  }
  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/byoctestsse-sse"
      principal_id = "00000000-0000-0000-0000-000000000002"
    }
  }
  mock_resource "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/byoctestsse"
    }
  }
}

variables {
  storage_account_name       = "byoctestsse"
  resource_group_name        = "test"
  location                   = "eastus"
  container_name             = "data"
  virtual_network_subnet_ids = []
}

run "microsoft_managed_default" {
  command = apply
  assert {
    condition = (
      length(azurerm_storage_account.main.customer_managed_key) == 0 &&
      length(azurerm_storage_account.main.identity) == 0 &&
      length(azurerm_user_assigned_identity.sse) == 0 &&
      length(azurerm_role_assignment.sse) == 0 &&
      length(data.azurerm_key_vault_key.sse) == 0 &&
      output.sse_identity_id == null
    )
    error_message = "Default deployments must not create CMK resources or change the storage identity."
  }
}

run "enable_automatic_rotation" {
  command = apply
  variables {
    customer_managed_key = {
      key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.KeyVault/vaults/byoc-test"
      key_name     = "storage-key"
    }
  }
  assert {
    condition = (
      azurerm_storage_account.main.customer_managed_key[0].key_vault_key_id == "https://byoc-test.vault.azure.net/keys/storage-key" &&
      azurerm_storage_account.main.customer_managed_key[0].user_assigned_identity_id == output.sse_identity_id &&
      contains(azurerm_storage_account.main.identity[0].identity_ids, output.sse_identity_id)
    )
    error_message = "CMK must use a versionless key and the dedicated identity attached to Storage."
  }
  assert {
    condition = (
      azurerm_role_assignment.sse[0].scope == "${var.customer_managed_key.key_vault_id}/keys/storage-key" &&
      azurerm_role_assignment.sse[0].role_definition_name == "Key Vault Crypto Service Encryption User" &&
      azurerm_role_assignment.sse[0].principal_id == azurerm_user_assigned_identity.sse[0].principal_id
    )
    error_message = "Grant the dedicated identity encryption access only to the selected key."
  }
}

run "pin_version" {
  command = apply
  variables {
    customer_managed_key = {
      key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.KeyVault/vaults/byoc-test"
      key_name     = "storage-key"
      key_version  = "0123456789abcdef0123456789abcdef"
    }
  }
  assert {
    condition     = azurerm_storage_account.main.customer_managed_key[0].key_vault_key_id == "https://byoc-test.vault.azure.net/keys/storage-key/0123456789abcdef0123456789abcdef"
    error_message = "A pinned version must not silently use the latest key."
  }
}

run "disable_cmk" {
  command = apply
  assert {
    condition     = length(azurerm_storage_account.main.customer_managed_key) == 0 && length(azurerm_role_assignment.sse) == 0
    error_message = "Removing CMK configuration must remove its binding and permissions."
  }
}

run "reject_invalid_version" {
  command = plan
  variables {
    customer_managed_key = {
      key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.KeyVault/vaults/byoc-test"
      key_name     = "storage-key"
      key_version  = ""
    }
  }
  expect_failures = [var.customer_managed_key]
}

run "reject_unsupported_account_kind" {
  command = plan
  variables {
    account_kind = "Storage"
    customer_managed_key = {
      key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.KeyVault/vaults/byoc-test"
      key_name     = "storage-key"
    }
  }
  expect_failures = [azurerm_storage_account.main]
}

run "reject_vault_url_instead_of_arm_id" {
  command = plan
  variables {
    customer_managed_key = {
      key_vault_id = "https://byoc-test.vault.azure.net"
      key_name     = "storage-key"
    }
  }
  expect_failures = [var.customer_managed_key]
}

run "reject_empty_key_name" {
  command = plan
  variables {
    customer_managed_key = {
      key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.KeyVault/vaults/byoc-test"
      key_name     = ""
    }
  }
  expect_failures = [var.customer_managed_key]
}

run "disabled_switch_ignores_custom_key" {
  command = apply
  variables {
    enable_cmk_sse = false
    customer_managed_key = {
      key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.KeyVault/vaults/byoc-test"
      key_name     = "storage-key"
    }
  }
  assert {
    condition = (
      length(azurerm_storage_account.main.customer_managed_key) == 0 &&
      length(data.azurerm_key_vault_key.sse) == 0 &&
      length(azurerm_user_assigned_identity.sse) == 0 &&
      length(azurerm_role_assignment.sse) == 0
    )
    error_message = "Disabling CMK-SSE must use platform keys without reading or authorizing the supplied custom key."
  }
}
