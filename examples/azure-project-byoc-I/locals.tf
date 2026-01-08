resource "random_id" "short_uuid" {
  byte_length = 3  # 3 bytes = 6 characters when base64 encoded
}

locals {
  # Azure region extracted from Zilliz cloud settings, removing "az-" prefix
  # Normalizes region format from Zilliz naming convention to standard Azure region names
  region = replace(data.zillizcloud_byoc_i_project_settings.this.region, "az-", "")

  # Resource group name extracted from Zilliz cloud configuration used for all resources
  # TODO: check it from the project settings.
  resource_group_name = data.zillizcloud_byoc_i_project_settings.this.resource_group_name

  # Data plane identifier from Zilliz cloud configuration
  # Used to associate Azure resources with the correct Zilliz data plane instance
  dataplane_id = data.zillizcloud_byoc_i_project_settings.this.data_plane_id

  # Zilliz project identifier for resource tagging and organization
  # Links Azure resources back to the specific Zilliz cloud project
  project_id = data.zillizcloud_byoc_i_project_settings.this.project_id

  # Truncated project identifier for resource naming, limited to first 10 characters
  # Extracted from the Zilliz cloud BYOC project settings to ensure uniqueness
  short_project_id = substr(local.project_id, 0, 10)
  
  # Standardized naming prefix for all Azure resources created by this Terraform configuration
  # Combines "zilliz" brand, short project ID, and random hex for global uniqueness
  prefix_name = "zilliz-${local.short_project_id}-${random_id.short_uuid.hex}"

  # Common tags merged with user-provided tags
  common_tags = merge(
    {
      Vendor      = "zilliz-byoc"
      ManagedBy   = "terraform"
      Project     = local.project_id
      Environment = try(var.tags.Environment, "Production")
    },
    var.tags
  )

  vnet_id = module.vnet.vnet_id

  subnet_ids = module.vnet.subnet_ids

  storage_account_id = module.storage_account.storage_account_id
  storage_account_name = module.storage_account.storage_account_name
  storage_container_name = module.storage_account.container_name

  aks_cluster_id = module.milvus_aks.cluster_id
  aks_cluster_name = module.milvus_aks.cluster_name

  # ============================================================================
  # VNet Configuration
  # ============================================================================
  # Default VNet configuration - CIDR is required when create_vnet is true
  vnet_config = {
    name                = "${local.prefix_name}-vnet"
    location            = local.location
    resource_group_name = local.resource_group_name
    cidr                = try(var.vnet.cidr, "10.0.0.0/16") # Default CIDR is 10.0.0.0/16

    # Subnet configuration - auto-split enabled by default
    auto_split_subnets = true
    custom_subnets     = try(var.vnet.custom_subnets, {})

    # NAT Gateway configuration - created by default for outbound internet access
    create_nat_gateway = true
    nat_gateway_name   = "${local.prefix_name}-nat-gateway"

    tags = local.common_tags
  }

  # ============================================================================
  # Storage Account Configuration
  # ============================================================================
  storage_config = {
    name                = "${local.prefix_name}-storage-account"
    location            = local.location
    resource_group_name = local.resource_group_name

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
    container_name      = "${local.prefix_name}-storage-container"
    container_metadata  = try(var.storage.container_metadata, {})
    container_access_type = try(var.storage.container_access_type, "private")

    tags = local.common_tags
  }

  # Storage container scope for storage identity role assignment
  # Format: /subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{account}/blobServices/default/containers/{container}
  storage_container_scope = "${local.storage_account_id}/blobServices/default/containers/${local.storage_container_name}"

  # ============================================================================
  # Storage Identity Configuration
  # ============================================================================
  # Storage identity configuration - created after storage account
  storage_identity_config = var.create_storage_identity ? {
    name                = "${local.prefix_name}-storage-identity"
    location            = local.location
    resource_group_name = var.resource_group_name
    tags                = local.common_tags
  } : null

  # ============================================================================
  # Identity Configuration
  # ============================================================================
  # Storage Identities Configuration
  # ============================================================================
  storage_identities = [
    for identity in module.storage_identity[0].instance_identities : {
      client_id    = identity.client_id
      principal_id = identity.principal_id
      resource_id  = identity.object_id
    }
  ]

  common_storage_identity_id = module.storage_identity[0].storage_identity.resource_id

  # Maintenance Identity 
  maintenance_identity = {
    client_id    = module.milvus_aks[0].maintenance_identity_client_id
    principal_id = module.milvus_aks[0].maintenance_identity_principal_id
    resource_id  = module.milvus_aks[0].maintenance_identity_id
  }

  # Kubelet Identity 
  kubelet_identity = {
    client_id    = module.milvus_aks[0].kubelet_identity.client_id
    principal_id = module.milvus_aks[0].kubelet_identity.object_id
    resource_id  = module.milvus_aks[0].kubelet_identity.user_assigned_identity_id
  }

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
  # Private endpoint ID
  private_endpoint_id = var.enable_private_link && var.private_endpoint != null ? module.zilliz_private_endpoint[0].private_endpoint_id : null

  # ============================================================================
  # AKS Configuration
  # ============================================================================
  # Default AKS configuration - converts node_pools to k8s_node_groups format
  aks_config = {
    cluster_name        = "${local.prefix_name}-aks"
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

  ext_config = {
    aks_cluster_name = local.aks_cluster_name
    acr =  var.customer_acr
  }
}

