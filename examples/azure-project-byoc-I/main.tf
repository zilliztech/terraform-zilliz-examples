# Azure BYOC Project - BYOC-I Configuration
# This example creates a complete Azure BYOC infrastructure following AWS BYOC-I pattern:
# 1. Virtual Network with subnets
# 2. Storage Account
# 3. Storage Identity (User Assigned Managed Identity)
# 4. AKS Cluster for Milvus
# 5. Private Endpoint for Zilliz Cloud connectivity (optional)

# ============================================================================
# 1. Virtual Network Module (Conditional)
# ============================================================================
module "vnet" {
  count = var.create_vnet ? 1 : 0

  source = "../../modules/azure/byoc_i/default-virtual-networks"

  vnet_name           = local.vnet_config.name
  location            = local.vnet_config.location
  resource_group_name = local.vnet_config.resource_group_name
  vnet_cidr          = local.vnet_config.cidr

  create_nat_gateway = local.vnet_config.create_nat_gateway
  nat_gateway_name   = local.vnet_config.nat_gateway_name

  custom_tags = local.vnet_config.tags
}

# ============================================================================
# 2. Storage Account Module (Conditional)
# ============================================================================
module "storage_account" {
  count = var.create_storage_account ? 1 : 0

  source = "../../modules/azure/byoc_i/default-storageaccount"

  storage_account_name = local.storage_config.name
  resource_group_name  = local.storage_config.resource_group_name
  location             = local.storage_config.location

  account_tier             = local.storage_config.account_tier
  account_replication_type = local.storage_config.account_replication_type
  account_kind             = local.storage_config.account_kind
  minimum_tls_version      = local.storage_config.minimum_tls_version
  allow_blob_public_access = local.storage_config.allow_blob_public_access
  network_default_action   = local.storage_config.network_default_action
  public_network_access_enabled = local.storage_config.public_network_access_enabled

  # If storage_subnet_names is empty, allow all VNet subnets
  # Otherwise, only allow specified subnets
  virtual_network_subnet_ids = length(local.storage_subnet_names) > 0 ? [
    for subnet_name in local.storage_subnet_names : local.subnet_ids[subnet_name]
  ] : [
    for subnet_id in values(local.subnet_ids) : subnet_id
  ]

  container_name       = local.storage_container_name
  container_metadata   = local.storage_config.container_metadata
  container_access_type = local.storage_config.container_access_type

  custom_tags = local.storage_config.tags

  depends_on = [module.vnet]
}

# ============================================================================
# 3. Storage Identity Module (Conditional)
# ============================================================================
module "storage_identity" {
  count = var.create_storage_identity ? 1 : 0

  source = "../../modules/azure/byoc_i/default-storage-identity"

  name                = local.name_prefix
  location            = local.location
  resource_group_name = var.resource_group_name

  # Storage container scope for role assignment
  # Format: /subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{account}/blobServices/default/containers/{container}
  storage_container_scope = local.storage_container_scope

  custom_tags = local.common_tags

  depends_on = [module.storage_account]
}

# ============================================================================
# 4. AKS Cluster Module (Conditional)
# ============================================================================
module "milvus_aks" {
  count = var.create_aks ? 1 : 0

  source = "../../modules/azure/byoc_i/default-aks"

  prefix_name        = local.name_prefix
  cluster_name       = local.aks_config.cluster_name
  location           = local.aks_config.location
  resource_group_name = local.aks_config.resource_group_name
  subnet_id          = local.aks_subnet_id
  vnet_id            = local.vnet_id

  kubernetes_version = local.aks_config.kubernetes_version
  service_cidr       = local.aks_config.service_cidr

  default_node_pool = local.aks_config.default_node_pool
  k8s_node_groups   = local.aks_config.k8s_node_groups

  # Storage identity for federated credentials
  storage_identity_id = local.storage_identity_id

  # Optional AKS configuration
  acr_name     = var.acr_name
  acr_prefix   = var.acr_prefix
  agent_tag    = var.agent_tag
  env          = var.env
  dataplane_id = var.dataplane_id
  auth_token = var.auth_token
  custom_tags = local.common_tags

  depends_on = [module.vnet, module.zilliz_private_endpoint, module.storage_identity]
}

# ============================================================================
# 5. Private Endpoint Module (Conditional - Created after AKS)
# ============================================================================
# Private Link for Zilliz Cloud connectivity (not Storage Account private endpoint)
module "zilliz_private_endpoint" {
  count = var.enable_private_link && local.private_endpoint_config != null ? 1 : 0

  source = "../../modules/azure/byoc_i/default-privatelink"

  private_endpoint_name = local.private_endpoint_config.name
  location             = local.private_endpoint_config.location
  resource_group_name  = local.private_endpoint_config.resource_group_name
  subnet_id            = local.private_endpoint_config.subnet_id
  vnet_id              = local.private_endpoint_config.vnet_id

  custom_tags = local.private_endpoint_config.tags

  depends_on = [module.vnet]
}
