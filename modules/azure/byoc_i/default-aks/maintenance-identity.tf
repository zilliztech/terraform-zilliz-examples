# Maintenance Identity - User Assigned Managed Identity
# This identity is used by Zilliz infrastructure services to manage AKS clusters, VMSS, networks, and workload identity federation
resource "azurerm_user_assigned_identity" "maintenance" {

  name                = local.maintenance_identity_name
  location            = local.location
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

# Role Assignment 1: Network Contributor on VNet
# This allows the maintenance identity to manage network resources in the VNet
resource "azurerm_role_assignment" "maintenance_vnet_network_contributor" {

  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.maintenance.principal_id

  description = "Allow maintenance identity to manage network resources in VNet"
}

# Role Assignment 2: Managed Identity Federated Identity Credential Contributor on all instance storage identities
# This allows the maintenance identity to create/update/delete federated identity credentials on all instance storage identities
# This is needed for workload identity federation
resource "azurerm_role_assignment" "maintenance_instance_storage_identity_federated_credential" {
  # Use index as key to avoid "for_each value includes values derived from resource attributes" error
  for_each = { for idx, id in var.instance_storage_identity_ids : tostring(idx) => id }

  scope                = each.value
  role_definition_name = "Managed Identity Federated Identity Credential Contributor"
  principal_id         = azurerm_user_assigned_identity.maintenance.principal_id

  description = "Allow maintenance identity to manage federated identity credentials on instance storage identity"
}

# Role Assignment 3: AKS Contributor on AKS cluster
# This allows the maintenance identity to create, update, and delete AKS clusters and node groups
resource "azurerm_role_assignment" "maintenance_aks_contributor" {

  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service Contributor Role"
  principal_id         = azurerm_user_assigned_identity.maintenance.principal_id

  description = "Allow maintenance identity to manage AKS clusters and node groups"
}

resource "azurerm_role_assignment" "maintenance_vmss_contributor" {
  scope                = azurerm_kubernetes_cluster.main.node_resource_group_id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_user_assigned_identity.maintenance.principal_id

  description = "Allow maintenance identity to manage VMSS in AKS node resource group"
}

# Data sources to get AKS-managed identities
# These identities are automatically created by AKS in the node resource group
data "azurerm_user_assigned_identity" "agentpool" {
  name                = "${var.cluster_name}-agentpool"
  resource_group_name = azurerm_kubernetes_cluster.main.node_resource_group
}

data "azurerm_user_assigned_identity" "azurepolicy" {
  name                = "azurepolicy-${var.cluster_name}"
  resource_group_name = azurerm_kubernetes_cluster.main.node_resource_group
}

# Role Assignment: User Assigned Managed Identity Operator on agent pool and azurepolicy managed identities
# These role assignments allow the maintenance identity to assign these identities to VMSS

resource "azurerm_role_assignment" "maintenance_agentpool_identity_operator" {
  scope                = data.azurerm_user_assigned_identity.agentpool.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.maintenance.principal_id

  description = "Allow maintenance identity to assign user-assigned identity to VMSS (agentpool) in AKS node resource group"
}

resource "azurerm_role_assignment" "maintenance_azurepolicy_identity_operator" {
  scope                = data.azurerm_user_assigned_identity.azurepolicy.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.maintenance.principal_id

  description = "Allow maintenance identity to assign user-assigned identity to VMSS (azurepolicy) in AKS node resource group"
}