# Azure Kubernetes Service
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = local.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.cluster_name}-dns"

  # Identity
  # identity {
  #   type = "UserAssigned"
  #   identity_ids = [var.kubelet_identity.user_assigned_identity_id]
  # }
  identity {
    type = "SystemAssigned"
  }

  node_os_upgrade_channel = "None"

  # Network Profile
  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    network_data_plane = "azure"
    load_balancer_sku  = "standard"
    service_cidr       = var.service_cidr
    dns_service_ip     = "10.255.0.10"
    outbound_type      = "loadBalancer"
    service_cidrs      = [var.service_cidr]

    load_balancer_profile {
      backend_pool_type         = "NodeIPConfiguration"
      managed_outbound_ip_count = 1
    }
  }

  # Private Cluster Configuration
  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = true
  private_dns_zone_id                 = "System"

  # API Server Access Profile (Private Cluster)
  # api_server_access_profile {
  #   authorized_ip_ranges = []
  # }

  # Default Node Pool
  # Similar to AWS EKS pattern with standardized naming and labels
  default_node_pool {
    name                         = "agentpool"
    vm_size                      = var.default_node_pool.vm_size
    node_count                   = var.default_node_pool.node_count
    vnet_subnet_id               = var.subnet_id
    max_pods                     = 110
    os_disk_size_gb              = 128
    os_disk_type                 = "Managed"
    os_sku                       = "Ubuntu"
    type                         = "VirtualMachineScaleSets"
    auto_scaling_enabled         = var.default_node_pool.enable_auto_scaling
    min_count                    = var.default_node_pool.min_count
    max_count                    = var.default_node_pool.max_count
    only_critical_addons_enabled = true
    orchestrator_version         = var.kubernetes_version
    scale_down_mode              = "Delete"

    # Use standardized labels similar to AWS EKS pattern
    # Ensure zilliz-group-name is present
    node_labels = local.default_node_labels

    temporary_name_for_rotation = "agentpool"
    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }
  }

  # RBAC
  role_based_access_control_enabled = true

  # Addons
  azure_policy_enabled = true

  # Auto Scaler Profile
  auto_scaler_profile {
    balance_similar_node_groups                   = false
    daemonset_eviction_for_empty_nodes_enabled    = false
    daemonset_eviction_for_occupied_nodes_enabled = true
    empty_bulk_delete_max                         = "10"
    expander                                      = "random"
    max_graceful_termination_sec                  = "600"
    max_node_provisioning_time                    = "15m"
    max_unready_nodes                             = 3
    max_unready_percentage                        = 45
    new_pod_scale_up_delay                        = "0s"
    scale_down_delay_after_add                    = "10m"
    scale_down_delay_after_delete                 = "10s"
    scale_down_delay_after_failure                = "3m"
    scale_down_unneeded                           = "10m"
    scale_down_unready                            = "20m"
    scale_down_utilization_threshold              = "0.5"
    scan_interval                                 = "10s"
    skip_nodes_with_local_storage                 = false
    skip_nodes_with_system_pods                   = true
  }

  # OIDC Issuer Profile
  oidc_issuer_enabled = true

  # Workload Identity
  workload_identity_enabled = true

  # Use common_tags with Vendor=zilliz-byoc (similar to AWS EKS pattern)
  tags = local.common_tags
}

# Network Contributor role assignment for AKS identity
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

# Data source to get current subscription
data "azurerm_client_config" "current" {}
