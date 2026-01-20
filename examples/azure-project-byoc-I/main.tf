# Azure BYOC Project - BYOC-I Configuration
# This example creates a complete Azure BYOC infrastructure following AWS BYOC-I pattern:
# 1. Virtual Network with subnets
# 2. Storage Account
# 3. Storage Identity (User Assigned Managed Identity)
# 4. AKS Cluster for Milvus
# 5. Private Endpoint for Zilliz Cloud connectivity (optional)
# 6. Zilliz Cloud Project Agent Module
# 7. Zilliz Cloud Project Module

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# check if the subscription_id matches the actual Azure provider subscription
check "subscription_id_match" {
  assert {
    condition     = var.subscription_id == data.azurerm_client_config.current.subscription_id
    error_message = "Variable subscription_id (${var.subscription_id}) does not match the actual Azure provider subscription (${data.azurerm_client_config.current.subscription_id}). Please ensure they are consistent."
  }
}

# check if the resource group exists in the specified subscription (from variables)
check "resource_group_in_correct_subscription" {
  assert {
    condition     = data.azurerm_resource_group.main.id == "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
    error_message = "Resource group '${var.resource_group_name}' does not exist in subscription '${var.subscription_id}'. Found: ${data.azurerm_resource_group.main.id}"
  }
}

data "zillizcloud_byoc_i_project_settings" "this" {
  project_id    = var.project_id
  data_plane_id = var.dataplane_id
}

resource "random_id" "short_uuid" {
  byte_length = 3 # 3 bytes = 6 characters when base64 encoded
}

# ============================================================================
# 1. Virtual Network Module
# ============================================================================
module "vnet" {
  source = "../../modules/azure/byoc_i/default-virtual-networks"

  vnet_name           = local.vnet_config.name
  location            = local.vnet_config.location
  resource_group_name = local.vnet_config.resource_group_name
  vnet_cidr           = local.vnet_config.cidr

  create_nat_gateway = local.vnet_config.create_nat_gateway
  nat_gateway_name   = local.vnet_config.nat_gateway_name

  custom_tags = local.vnet_config.tags
}

# ============================================================================
# 2. Storage Account Module
# ============================================================================
module "storage_account" {
  source = "../../modules/azure/byoc_i/default-storageaccount"

  storage_account_name = local.storage_config.name
  resource_group_name  = local.storage_config.resource_group_name
  location             = local.storage_config.location

  account_tier                  = local.storage_config.account_tier
  account_replication_type      = local.storage_config.account_replication_type
  account_kind                  = local.storage_config.account_kind
  minimum_tls_version           = local.storage_config.minimum_tls_version
  allow_blob_public_access      = local.storage_config.allow_blob_public_access
  network_default_action        = local.storage_config.network_default_action
  public_network_access_enabled = local.storage_config.public_network_access_enabled

  virtual_network_subnet_ids = local.storage_config.virtual_network_subnet_ids

  container_name        = local.storage_config.container_name
  container_metadata    = local.storage_config.container_metadata
  container_access_type = local.storage_config.container_access_type

  custom_tags = local.storage_config.tags

  depends_on = [module.vnet]
}

# ============================================================================
# 3. Storage Identity Module
# ============================================================================
module "storage_identity" {
  source = "../../modules/azure/byoc_i/default-storage-identity"

  name                = local.name_prefix
  location            = local.location
  resource_group_name = local.resource_group_name

  # Storage account scope for role assignment
  # Format: /subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{account}
  storage_account_scope = local.storage_account_scope

  custom_tags = local.common_tags

  depends_on = [module.storage_account]
}

# ============================================================================
# 4. AKS Cluster Module
# ============================================================================
module "milvus_aks" {
  source = "../../modules/azure/byoc_i/default-aks"

  enable_private_endpoint = local.enable_private_link
  prefix_name             = local.name_prefix
  cluster_name            = local.aks_config.cluster_name
  location                = local.aks_config.location
  resource_group_name     = local.aks_config.resource_group_name
  subnet_id               = local.aks_subnet_id
  vnet_id                 = local.vnet_id

  kubernetes_version = local.aks_config.kubernetes_version
  service_cidr       = local.aks_config.service_cidr

  default_node_pool = local.aks_config.default_node_pool
  k8s_node_groups   = local.aks_config.k8s_node_groups

  # Instance storage identities for federated credentials
  instance_storage_identity_ids = local.instance_storage_identity_ids
  storage_identity_id = local.common_storage_identity_id

  # Optional AKS configuration
  env          = var.env
  dataplane_id = local.data_plane_id
  agent_tag    = local.agent_config.tag
  auth_token   = local.agent_config.auth_token
  custom_tags  = local.common_tags

  depends_on = [module.vnet, module.zilliz_private_endpoint, module.storage_identity]
}

# ============================================================================
# 5. Private Endpoint Module (Conditional - Created after AKS)
# ============================================================================
# Private Link for Zilliz Cloud connectivity (not Storage Account private endpoint)
module "zilliz_private_endpoint" {
  count = local.enable_private_link ? 1 : 0

  source = "../../modules/azure/byoc_i/default-privatelink"

  private_endpoint_name = local.private_endpoint_config.name
  location              = local.private_endpoint_config.location
  resource_group_name   = local.private_endpoint_config.resource_group_name
  subnet_id             = local.private_endpoint_config.subnet_id
  vnet_id               = local.private_endpoint_config.vnet_id

  custom_tags = local.private_endpoint_config.tags

  depends_on = [module.vnet]
}

# ============================================================================
# 6. Zilliz Cloud Project Agent Module
# ============================================================================

resource "zillizcloud_byoc_i_project_agent" "this" {
  project_id    = local.project_id
  data_plane_id = local.data_plane_id

  depends_on = [module.milvus_aks]
}

# ============================================================================
# 7. Zilliz Cloud Project Module
# ============================================================================
resource "zillizcloud_byoc_i_project" "this" {

  project_id    = local.project_id
  data_plane_id = local.data_plane_id

  azure = {
    region = data.zillizcloud_byoc_i_project_settings.this.region

    network = {
      vnet_id             = local.vnet_id
      subnet_ids          = toset(values(local.subnet_ids))
      nsg_ids             = []
      private_endpoint_id = local.private_endpoint_id
    }
    identity = {
      storages    = local.storage_identities
      kubelet     = local.kubelet_identity
      maintenance = local.maintenance_identity
    }
    storage = {
      storage_account_name = local.storage_account_name
      container_name       = local.storage_config.container_name
    }
  }

  // depend on private link to establish agent tunnel connection
  depends_on = [zillizcloud_byoc_i_project_agent.this,
  module.milvus_aks, module.zilliz_private_endpoint, module.storage_identity]
  lifecycle {
    ignore_changes  = [data_plane_id, project_id, azure, ext_config]
    prevent_destroy = true
  }

  ext_config = base64encode(jsonencode(local.ext_config))
}


output "data_plane_id" {
  value = local.data_plane_id
}

output "project_id" {
  value = local.project_id
}

output "destroy_info" {
  value = <<EOT
To destroy this infrastructure, run the following command:

ZILLIZCLOUD_API_KEY=<api_key> terraform destroy \
  -var="dataplane_id=${local.data_plane_id}" \
  -var="project_id=${local.project_id}"

Note: Replace <api_key> with your actual Zilliz Cloud API key.
EOT
}