mock_provider "azurerm" {

  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mock"
      principal_id = "00000000-0000-0000-0000-000000000002"
      client_id    = "00000000-0000-0000-0000-000000000003"
    }
  }
  mock_data "azurerm_user_assigned_identity" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mock"
    }
  }
  mock_resource "azurerm_kubernetes_cluster" {
    defaults = {
      id                     = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ContainerService/managedClusters/test-aks"
      node_resource_group    = "test-nodes"
      node_resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test-nodes"
      oidc_issuer_url        = "https://test.example.com/issuer/"
      kube_config            = [{ host = "https://test.example.com", client_key = "test", client_certificate = "test", cluster_ca_certificate = "test", username = "test", password = "test" }]
    }
  }
  mock_resource "azurerm_disk_encryption_set" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Compute/diskEncryptionSets/test-aks-sse" }
  }
  mock_data "azurerm_resources" {
    defaults = {
      resources = [{ id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Compute/virtualMachineScaleSets/search", name = "search", resource_group_name = "test", type = "Microsoft.Compute/virtualMachineScaleSets", location = "southeastasia", tags = {} }]
    }
  }

  mock_data "azurerm_location" {
    defaults = { location = "southeastasia" }
  }
  mock_data "azurerm_client_config" {
    defaults = { subscription_id = "00000000-0000-0000-0000-000000000001" }
  }
  mock_data "azurerm_key_vault_key" {
    defaults = { versionless_id = "https://byoc-test.vault.azure.net/keys/disk-key" }
  }
}
mock_provider "azapi" {}
override_resource {
  target = azapi_resource_action.aks_run_command
  values = { output = { properties = { exitCode = 0, logs = "offline" } } }
}

variables {
  cluster_name        = "test-aks"
  resource_group_name = "test"
  location            = "southeastasia"
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/aks"
  vnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test"
  storage_identity_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/storage"
  agent_tag           = "test"
  auth_token          = "offline-test"
  dataplane_id        = "zilliz-byoc-azure-southeastasia-test"
  k8s_node_groups = {
    core        = { vm_size = "Standard_D4as_v5", min_size = 1, max_size = 3, desired_size = 1, os_disk_size_gb = 128 }
    search      = { vm_size = "Standard_D8ds_v5", min_size = 1, max_size = 3, desired_size = 1, os_disk_size_gb = 128 }
    index       = { vm_size = "Standard_D4as_v5", min_size = 1, max_size = 3, desired_size = 1, os_disk_size_gb = 128 }
    fundamental = { vm_size = "Standard_D4as_v5", min_size = 1, max_size = 3, desired_size = 1, os_disk_size_gb = 128 }
  }
}

run "platform_keys_by_default" {
  command = plan
  assert {
    condition = (
      azurerm_kubernetes_cluster.main.disk_encryption_set_id == null &&
      azurerm_kubernetes_cluster.main.identity[0].type == "SystemAssigned" &&
      length(azurerm_disk_encryption_set.sse) == 0 &&
      length(azurerm_user_assigned_identity.disk_sse) == 0 &&
      length(azurerm_user_assigned_identity.cmk_control_plane) == 0 &&
      length(data.azurerm_key_vault_key.sse) == 0
    )
    error_message = "No key must preserve the system identity and platform encryption without CMK resources."
  }
}

run "customer_key_with_rotation" {
  command = apply
  variables {
    customer_managed_key = {
      key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.KeyVault/vaults/byoc-test"
      key_name     = "disk-key"
    }
  }
  override_resource {
    target = azurerm_disk_encryption_set.sse[0]
    values = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Compute/diskEncryptionSets/test-aks-sse" }
  }
  assert {
    condition = (
      azurerm_kubernetes_cluster.main.disk_encryption_set_id == azurerm_disk_encryption_set.sse[0].id &&
      azurerm_kubernetes_cluster.main.identity[0].type == "UserAssigned" &&
      azurerm_kubernetes_cluster_node_pool.search.os_disk_type == "Ephemeral" &&
      azurerm_kubernetes_cluster_node_pool.core.os_disk_type == "Managed"
    )
    error_message = "Bind DES at cluster scope without changing the node pool disk types."
  }
  assert {
    condition = (
      azurerm_disk_encryption_set.sse[0].key_vault_key_id == "https://byoc-test.vault.azure.net/keys/disk-key" &&
      azurerm_disk_encryption_set.sse[0].auto_key_rotation_enabled &&
      azurerm_role_assignment.disk_key[0].scope == "${var.customer_managed_key.key_vault_id}/keys/disk-key" &&
      azurerm_role_assignment.disk_key[0].role_definition_name == "Key Vault Crypto Service Encryption User" &&
      azurerm_role_assignment.aks_des_reader[0].role_definition_name == "Reader" &&
      azurerm_role_assignment.aks_des_reader[0].scope == azurerm_disk_encryption_set.sse[0].id
    )
    error_message = "Use a rotating key with key-scoped crypto permissions and DES-scoped Reader."
  }
}

run "pinned_customer_key" {
  command = plan
  variables {
    customer_managed_key = {
      key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.KeyVault/vaults/byoc-test"
      key_name     = "disk-key"
      key_version  = "0123456789abcdef0123456789abcdef"
    }
  }
  assert {
    condition = (
      azurerm_disk_encryption_set.sse[0].key_vault_key_id == "https://byoc-test.vault.azure.net/keys/disk-key/0123456789abcdef0123456789abcdef" &&
      !azurerm_disk_encryption_set.sse[0].auto_key_rotation_enabled
    )
    error_message = "An explicit key version must disable automatic DES rotation."
  }
}

run "disabled_switch_ignores_customer_key" {
  command = plan
  variables {
    enable_cmk_sse = false
    customer_managed_key = {
      key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.KeyVault/vaults/byoc-test"
      key_name     = "disk-key"
    }
  }
  assert {
    condition = (
      azurerm_kubernetes_cluster.main.disk_encryption_set_id == null &&
      azurerm_kubernetes_cluster.main.identity[0].type == "SystemAssigned" &&
      length(data.azurerm_key_vault_key.sse) == 0 &&
      length(azurerm_disk_encryption_set.sse) == 0 &&
      length(azurerm_role_assignment.disk_key) == 0 &&
      length(azurerm_role_assignment.aks_des_reader) == 0
    )
    error_message = "The disk switch must bypass all custom-key resources and use platform encryption."
  }
}

run "invalid_version" {
  command = plan
  variables {
    customer_managed_key = {
      key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.KeyVault/vaults/byoc-test"
      key_name     = "disk-key"
      key_version  = ""
    }
  }
  expect_failures = [var.customer_managed_key]
}
