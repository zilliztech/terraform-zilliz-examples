# Local values for configuration abstraction and module organization
data "azurerm_location" "current" {
  location = var.location
}

locals {

  location = data.azurerm_location.current.location
  # Common naming prefix for all resources
  name_prefix = var.name

  # Common tags merged with user-provided tags
  common_tags = merge(
    {
      Vendor      = "zilliz-byoc"
      ManagedBy   = "terraform"
      Project     = var.name
      Environment = try(var.tags.Environment, "Production")
    },
    var.tags
  )

  # ============================================================================
  # Resource Selection Logic
  # ============================================================================
  # VNet ID selection - use customer VNet if provided, otherwise use created VNet
  vnet_id = var.create_vnet ? module.vnet[0].vnet_id : var.customer_vnet_id

  # Subnet IDs selection - use customer subnets if provided, otherwise use created subnets
  subnet_ids = var.create_vnet ? module.vnet[0].subnet_ids : var.customer_subnet_ids

  # Storage Account ID and name selection
  storage_account_id = var.create_storage_account ? module.storage_account[0].storage_account_id : var.customer_storage_account_id
  storage_account_name = var.create_storage_account ? module.storage_account[0].storage_account_name : var.customer_storage_account_name

  # Storage container name selection
  # When creating storage account: use provided name or default
  # When using existing: use customer provided name or default
  storage_container_name = var.create_storage_account ? (
    try(var.storage.container_name, null) != null && var.storage.container_name != "" ? var.storage.container_name : "zilliz-byoc-data"
  ) : (
    try(var.customer_storage_container_name, "") != "" ? var.customer_storage_container_name : "zilliz-byoc-data"
  )

  # Storage Identity ID selection
  storage_identity_id = var.create_storage_identity ? module.storage_identity[0].storage_identity.object_id : var.customer_storage_identity_id
  storage_identity_client_id = var.create_storage_identity ? module.storage_identity[0].storage_identity.client_id : var.customer_storage_identity_client_id
  storage_identity_principal_id = var.create_storage_identity ? module.storage_identity[0].storage_identity.principal_id : var.customer_storage_identity_principal_id

  # AKS Cluster ID and name selection
  aks_cluster_id = var.create_aks ? module.milvus_aks[0].cluster_id : var.customer_aks_cluster_id
  aks_cluster_name = var.create_aks ? module.milvus_aks[0].cluster_name : var.customer_aks_cluster_name

  # ============================================================================
  # VNet Configuration
  # ============================================================================
  # Default VNet configuration - CIDR is required when create_vnet is true
  vnet_config = var.create_vnet ? {
    name                = "${local.name_prefix}-vnet"
    location            = local.location
    resource_group_name = var.resource_group_name
    cidr                = try(var.vnet.cidr, "")

    # Subnet configuration - auto-split enabled by default
    auto_split_subnets = true
    custom_subnets     = try(var.vnet.custom_subnets, {})

    # NAT Gateway configuration - created by default for outbound internet access
    create_nat_gateway = true
    nat_gateway_name   = "${local.name_prefix}-nat-gateway"

    tags = local.common_tags
  } : null

  # ============================================================================
  # Storage Account Configuration
  # ============================================================================
  storage_config = var.create_storage_account ? {
    name                = try(var.storage.name, "")
    location            = local.location
    resource_group_name = var.resource_group_name

    # Storage account properties
    account_tier             = try(var.storage.account_tier, "Standard")
    account_replication_type = try(var.storage.account_replication_type, "RAGRS")
    account_kind             = try(var.storage.account_kind, "StorageV2")
    minimum_tls_version      = try(var.storage.minimum_tls_version, "TLS1_2")

    # Network configuration - default: Allow all VNet subnets
    network_default_action        = try(var.storage.network_default_action, "Allow")
    public_network_access_enabled = try(var.storage.public_network_access_enabled, true)
    allow_blob_public_access     = try(var.storage.allow_blob_public_access, false)

    # Container configuration
    container_name      = local.storage_container_name
    container_metadata  = try(var.storage.container_metadata, {})
    container_access_type = try(var.storage.container_access_type, "private")

    tags = local.common_tags
  } : null

  # Storage account subnet names
  # If allowed_subnet_names is empty, allow all VNet subnets (will be resolved in main.tf)
  # If specified, only allow those specific subnets
  storage_subnet_names = length(try(var.storage.allowed_subnet_names, [])) > 0 ? var.storage.allowed_subnet_names : []

  # Storage container scope for storage identity role assignment
  # Format: /subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{account}/blobServices/default/containers/{container}
  storage_container_scope = "${local.storage_account_id}/blobServices/default/containers/${local.storage_container_name}"

  # ============================================================================
  # Storage Identity Configuration
  # ============================================================================
  # Storage identity configuration - created after storage account
  storage_identity_config = var.create_storage_identity ? {
    name                = local.name_prefix
    location            = local.location
    resource_group_name = var.resource_group_name
    tags                = local.common_tags
  } : null

  # ============================================================================
  # Private Endpoint Configuration (for Zilliz Cloud Private Link)
  # ============================================================================
  # Private endpoint configuration - only created if enable_private_link is true
  # This is for Zilliz Cloud private link, not Storage Account private endpoint
  private_endpoint_config = var.enable_private_link && var.private_endpoint != null ? {
    name                = var.private_endpoint.name
    location            = local.location
    resource_group_name = var.resource_group_name
    subnet_id           = local.subnet_ids[try(var.private_endpoint.subnet_name, "privatelink")]
    vnet_id             = local.vnet_id
    tags                = local.common_tags
  } : null

  # Private endpoint subnet name
  private_endpoint_subnet_name = var.enable_private_link && var.private_endpoint != null ? try(var.private_endpoint.subnet_name, "privatelink") : null

  # ============================================================================
  # AKS Configuration
  # ============================================================================
  # Default AKS configuration - converts node_pools to k8s_node_groups format
  aks_config = {
    cluster_name        = "${local.name_prefix}-aks"
    location            = local.location
    resource_group_name = var.resource_group_name

    # Kubernetes configuration - all use defaults
    kubernetes_version = null  # Use latest available version
    service_cidr       = "10.255.0.0/16"  # Default value, can be overridden via variable

    # Default node pool configuration - always use defaults
    default_node_pool = {
      vm_size             = "Standard_D4as_v5"
      node_count          = 1
      min_count           = 1
      max_count           = 5
      enable_auto_scaling = true
    }

    # Convert node_pools to k8s_node_groups format (similar to AWS EKS pattern)
    k8s_node_groups = {
      for pool in var.aks.node_pools : pool.name => {
        vm_size            = pool.vm_size
        min_size           = pool.min_count
        max_size           = pool.max_count
        desired_size       = pool.node_count
        os_disk_size_gb    = pool.os_disk_size_gb
        os_disk_type       = pool.os_disk_type
        node_labels        = pool.node_labels
        enable_auto_scaling = pool.enable_auto_scaling
      }
    }

    tags = local.common_tags
  }

  # AKS subnet name - always use milvus subnet
  aks_subnet_name = "milvus"

  # AKS subnet ID - use from subnet_ids map
  aks_subnet_id = local.subnet_ids[local.aks_subnet_name]

  # ============================================================================
  # Network Security Configuration
  # ============================================================================
  network_security = {
    enable_public_support = try(var.network_security.enable_public_support, false)
    allowed_subnets       = try(var.network_security.allowed_subnets, ["milvus", "default"])
  }
}

