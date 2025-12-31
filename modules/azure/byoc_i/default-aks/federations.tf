# AKS Federation credentials for workload identity
# This allows Kubernetes service accounts to authenticate using the storage identity
resource "azurerm_federated_identity_credential" "aks_storage_indexpool_federation" {
  name                = "indexpool-aks-federation"
  resource_group_name = var.resource_group_name
  parent_id           = var.storage_identity_id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject             = "system:serviceaccount:index-pool:milvus-bucket"

  depends_on = [
    azurerm_kubernetes_cluster.main
  ]
}

resource "azurerm_federated_identity_credential" "aks_storage_milvustool_federation" {
  name                = "milvus-tool-aks-federation"
  resource_group_name = var.resource_group_name
  parent_id           = var.storage_identity_id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject             = "system:serviceaccount:milvus-tool:milvus-bucket"

  depends_on = [
    azurerm_kubernetes_cluster.main
  ]
}

resource "azurerm_federated_identity_credential" "aks_storage_milvustool_federation" {
  name                = "milvus-tool-aks-federation"
  resource_group_name = var.resource_group_name
  parent_id           = var.storage_identity_id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject             = "system:serviceaccount:loki:loki-loki-distributed"

  depends_on = [
    azurerm_kubernetes_cluster.main
  ]
}

# AKS Federation credentials for workload identity
# This allows Kubernetes service accounts to authenticate using the maintenance identity
resource "azurerm_federated_identity_credential" "aks_maintenance_federation" {

  name                = "maintenance-aks-federation"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.maintenance.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject             = "system:serviceaccount:infra:infra-agent-sa"

  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_user_assigned_identity.maintenance
  ]
}

