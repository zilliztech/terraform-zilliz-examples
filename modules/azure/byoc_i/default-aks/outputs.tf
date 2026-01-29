output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "cluster_private_fqdn" {
  description = "Private FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.private_fqdn
}

output "cluster_portal_fqdn" {
  description = "Portal FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.portal_fqdn
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kube_config_host" {
  description = "Kubernetes cluster host"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.host
  sensitive   = true
}

output "kube_config_client_key" {
  description = "Kubernetes client key"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.client_key
  sensitive   = true
}

output "kube_config_client_certificate" {
  description = "Kubernetes client certificate"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.client_certificate
  sensitive   = true
}

output "kube_config_cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate
  sensitive   = true
}

output "node_resource_group" {
  description = "Name of the node resource group"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "identity" {
  description = "Identity of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.identity
}

output "node_pool_ids" {
  description = "IDs of all additional node pools (matching AWS EKS group names)"
  value = {
    core        = azurerm_kubernetes_cluster_node_pool.core.id
    search      = azurerm_kubernetes_cluster_node_pool.search.id
    index       = azurerm_kubernetes_cluster_node_pool.index.id
    fundamental = azurerm_kubernetes_cluster_node_pool.fundamental.id
  }
}

output "node_pool_names" {
  description = "Names of all additional node pools (matching AWS EKS group names)"
  value = [
    azurerm_kubernetes_cluster_node_pool.core.name,
    azurerm_kubernetes_cluster_node_pool.search.name,
    azurerm_kubernetes_cluster_node_pool.index.name,
    azurerm_kubernetes_cluster_node_pool.fundamental.name
  ]
}

# OIDC Issuer outputs
output "oidc_issuer_url" {
  description = "OIDC Issuer URL of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "oidc_issuer_url_last_two_segments" {
  description = "Last two segments of the OIDC Issuer URL (for milvus.openid configuration)"
  value       = join("/", slice(split("/", azurerm_kubernetes_cluster.main.oidc_issuer_url), length(split("/", azurerm_kubernetes_cluster.main.oidc_issuer_url)) - 3, length(split("/", azurerm_kubernetes_cluster.main.oidc_issuer_url))))
}

output "kubelet_identity" {
  description = "Kubelet identity of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity
}

# Maintenance Identity outputs
output "maintenance_identity_id" {
  description = "The ID of the maintenance user assigned managed identity"
  value       = azurerm_user_assigned_identity.maintenance.id
}

output "maintenance_identity_client_id" {
  description = "The client ID of the maintenance user assigned managed identity"
  value       = azurerm_user_assigned_identity.maintenance.client_id
}

output "maintenance_identity_principal_id" {
  description = "The principal ID of the maintenance user assigned managed identity"
  value       = azurerm_user_assigned_identity.maintenance.principal_id
}

# AKS-managed identities outputs
output "agentpool_identity_client_id" {
  description = "The client ID of the AKS agentpool managed identity"
  value       = data.azurerm_user_assigned_identity.agentpool.client_id
}

output "agentpool_identity_id" {
  description = "The ID of the AKS agentpool managed identity"
  value       = data.azurerm_user_assigned_identity.agentpool.id
}

output "azurepolicy_identity_client_id" {
  description = "The client ID of the AKS azurepolicy managed identity"
  value       = data.azurerm_user_assigned_identity.azurepolicy.client_id
}

output "azurepolicy_identity_id" {
  description = "The ID of the AKS azurepolicy managed identity"
  value       = data.azurerm_user_assigned_identity.azurepolicy.id
}

output "aks_all" {
  description = "All AKS-managed identities"
  value       = azurerm_kubernetes_cluster.main
  sensitive   = true
}

output "run_command_output" {
  description = "Output of the run command"
  value       = azapi_resource_action.aks_run_command
  sensitive   = true
}

output "search_userdata_patch_output" {
  description = "Output of the search userdata patch"
  value       = azapi_resource_action.search_userdata_patch
  sensitive   = true
}