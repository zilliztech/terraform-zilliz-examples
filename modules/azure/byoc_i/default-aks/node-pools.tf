# Additional Node Pools
# Similar to AWS EKS node groups pattern - separate resources with matching group names
locals {
  # Special handling for search node pool VMSS tag
  search_vmss_tag_value = "${var.cluster_name}-search-${substr(sha256(azurerm_kubernetes_cluster.main.id), 0, 8)}"
}

# azurerm_kubernetes_cluster_node_pool.core:
resource "azurerm_kubernetes_cluster_node_pool" "core" {
  name                  = "core"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  
  vm_size               = local.k8s_node_groups.core.vm_size
  node_count            = local.k8s_node_groups.core.desired_size
  vnet_subnet_id        = var.subnet_id
  os_disk_size_gb       = local.k8s_node_groups.core.os_disk_size_gb
  os_disk_type          = local.k8s_node_groups.core.os_disk_type
  os_sku                = "Ubuntu"
  auto_scaling_enabled  = local.k8s_node_groups.core.enable_auto_scaling
  min_count             = local.k8s_node_groups.core.min_size
  max_count             = local.k8s_node_groups.core.max_size
  
  # Labels matching AWS EKS core group pattern
  node_labels = local.core_node_labels
  
  temporary_name_for_rotation = "core"

  upgrade_settings {
    max_surge = "10%"
  }

  lifecycle {
    ignore_changes = [node_count]
  }

  tags = local.common_tags
}

# azurerm_kubernetes_cluster_node_pool.search:
resource "azurerm_kubernetes_cluster_node_pool" "search" {
  name                  = "search"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  
  vm_size               = local.k8s_node_groups.search.vm_size
  node_count            = local.k8s_node_groups.search.desired_size
  vnet_subnet_id        = var.subnet_id
  os_disk_size_gb       = local.k8s_node_groups.search.os_disk_size_gb
  os_disk_type          = local.k8s_node_groups.search.os_disk_type
  os_sku                = "Ubuntu"
  auto_scaling_enabled  = local.k8s_node_groups.search.enable_auto_scaling
  min_count             = local.k8s_node_groups.search.min_size
  max_count             = local.k8s_node_groups.search.max_size
  
  # Labels matching AWS EKS search group pattern
  node_labels = local.search_node_labels
  
  temporary_name_for_rotation = "search"

  upgrade_settings {
    max_surge = "10%"
  }

  lifecycle {
    ignore_changes = [node_count]
  }

  # Add special tag for VMSS identification: search-vmss-id = {cluster_name}-search-{hash}
  # Use cluster ID hash to ensure uniqueness
  tags = merge(
    local.common_tags,
    {
      "search-vmss-id" = local.search_vmss_tag_value
    }
  )
}

# azurerm_kubernetes_cluster_node_pool.index:
resource "azurerm_kubernetes_cluster_node_pool" "index" {
  name                  = "index"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  
  vm_size               = local.k8s_node_groups.index.vm_size
  node_count            = local.k8s_node_groups.index.desired_size
  vnet_subnet_id        = var.subnet_id
  os_disk_size_gb       = local.k8s_node_groups.index.os_disk_size_gb
  os_disk_type          = local.k8s_node_groups.index.os_disk_type
  os_sku                = "Ubuntu"
  auto_scaling_enabled  = local.k8s_node_groups.index.enable_auto_scaling
  min_count             = local.k8s_node_groups.index.min_size
  max_count             = local.k8s_node_groups.index.max_size
  
  # Labels matching AWS EKS index group pattern
  node_labels = local.index_node_labels
  
  temporary_name_for_rotation = "index"

  upgrade_settings {
    max_surge = "10%"
  }

  lifecycle {
    ignore_changes = [node_count]
  }

  tags = local.common_tags
}

# azurerm_kubernetes_cluster_node_pool.fundamental:
resource "azurerm_kubernetes_cluster_node_pool" "fundamental" {
  name                  = "fundamental"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  
  vm_size               = local.k8s_node_groups.fundamental.vm_size
  node_count            = local.k8s_node_groups.fundamental.desired_size
  vnet_subnet_id        = var.subnet_id
  os_disk_size_gb       = local.k8s_node_groups.fundamental.os_disk_size_gb
  os_disk_type          = local.k8s_node_groups.fundamental.os_disk_type
  os_sku                = "Ubuntu"
  auto_scaling_enabled  = local.k8s_node_groups.fundamental.enable_auto_scaling
  min_count             = local.k8s_node_groups.fundamental.min_size
  max_count             = local.k8s_node_groups.fundamental.max_size
  
  # Labels matching AWS EKS fundamental group pattern
  node_labels = local.fundamental_node_labels
  
  temporary_name_for_rotation = "fundamental"

  upgrade_settings {
    max_surge = "10%"
  }

  lifecycle {
    ignore_changes = [node_count]
  }

  tags = local.common_tags
}

# Search VMSS userdata patch (only for search node pool)
resource "azapi_resource_action" "search_userdata_patch" {
  type         = "Microsoft.Compute/virtualMachineScaleSets@2025-04-01"
  resource_id  = data.azurerm_resources.search_vmss.resources[0].id
  method       = "PATCH"

  body = {
    properties = {
      virtualMachineProfile = {
        osProfile = {
          customData = local.custom_data
        }
      }
    }
  }

  depends_on = [data.azurerm_resources.search_vmss]
}
