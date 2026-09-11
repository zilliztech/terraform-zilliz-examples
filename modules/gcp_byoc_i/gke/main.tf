resource "google_container_cluster" "this" {
  count = local.create_cluster ? 1 : 0

  project                  = var.gcp_project_id
  name                     = var.cluster_name
  location                 = var.gcp_region
  min_master_version       = var.kubernetes_version
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = var.network_self_link
  subnetwork               = var.primary_subnet_self_link
  networking_mode          = var.enable_ip_alias ? "VPC_NATIVE" : "ROUTES"
  node_locations           = var.gcp_zones
  deletion_protection      = var.deletion_protection
  resource_labels          = local.common_labels

  logging_service             = "none"
  monitoring_service          = "none"
  enable_intranode_visibility = var.enable_intranode_visibility

  dynamic "binary_authorization" {
    for_each = var.binary_authorization_evaluation_mode != "" ? [1] : []
    content {
      evaluation_mode = upper(var.binary_authorization_evaluation_mode)
    }
  }

  dynamic "identity_service_config" {
    for_each = var.enable_identity_service ? [1] : []
    content {
      enabled = true
    }
  }

  addons_config {
    dns_cache_config {
      enabled = true
    }

    gce_persistent_disk_csi_driver_config {
      enabled = true
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    http_load_balancing {
      disabled = false
    }

    network_policy_config {
      disabled = true
    }
  }

  cluster_autoscaling {
    enabled             = false
    autoscaling_profile = "BALANCED"
  }

  default_snat_status {
    disabled = true
  }

  dynamic "ip_allocation_policy" {
    for_each = var.enable_ip_alias ? [1] : []
    content {
      cluster_secondary_range_name  = var.pod_subnet_name
      services_secondary_range_name = var.service_subnet_name != "" ? var.service_subnet_name : null
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  private_cluster_config {
    enable_private_endpoint = var.enable_private_endpoint
    enable_private_nodes    = var.enable_private_nodes
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block

    master_global_access_config {
      enabled = true
    }
  }

  release_channel {
    channel = upper(var.release_channel)
  }

  workload_identity_config {
    workload_pool = var.workload_pool != "" ? var.workload_pool : "${var.gcp_project_id}.svc.id.goog"
  }

  # Temporary default pool (removed immediately) still creates boot disks,
  # which gcp.restrictNonCmekServices rejects without a KMS key.
  dynamic "node_config" {
    for_each = local.effective_boot_disk_kms_key_name != "" ? [1] : []
    content {
      boot_disk_kms_key = local.effective_boot_disk_kms_key_name
    }
  }

  lifecycle {
    # The default pool is deleted after creation. Only standalone node pools
    # should react to later boot-key changes; never replace the cluster for it.
    ignore_changes = [node_config]
  }

  dynamic "database_encryption" {
    for_each = var.enable_secrets_encryption ? [1] : []

    content {
      state    = "ENCRYPTED"
      key_name = local.effective_secrets_kms_key_name
    }
  }

  depends_on = [
    google_kms_crypto_key_iam_member.gke_secrets,
    terraform_data.secrets_encryption_validation,
  ]
}

resource "google_container_node_pool" "this" {
  for_each = local.node_groups

  project        = var.gcp_project_id
  name           = each.key
  location       = var.gcp_region
  cluster        = local.cluster.name
  node_locations = var.gcp_zones
  # GKE initializes this many nodes in EACH zone; quotas are totals across all zones.
  initial_node_count = var.node_initial_count != null ? var.node_initial_count : ceil(max(each.value.desired_size, each.value.min_size) / length(var.gcp_zones))
  max_pods_per_node  = each.key == "core" ? 110 : 32

  autoscaling {
    location_policy      = "ANY"
    total_min_node_count = each.value.min_size
    total_max_node_count = each.value.max_size
  }

  management {
    auto_repair  = var.node_auto_repair
    auto_upgrade = var.node_auto_upgrade
  }

  network_config {
    create_pod_range     = false
    enable_private_nodes = var.enable_private_nodes
    pod_range            = var.enable_ip_alias ? var.pod_subnet_name : null
  }

  node_config {
    disk_size_gb      = try(var.node_group_disk_overrides[each.key].disk_size_gb, var.node_disk_size_gb != null ? var.node_disk_size_gb : max(each.value.disk_size, 100))
    disk_type         = local.node_group_disk_types[each.key]
    image_type        = var.node_image_type
    labels            = local.node_group_labels[each.key]
    machine_type      = each.value.instance_types
    preemptible       = false
    service_account   = var.gke_node_sa_email
    spot              = upper(each.value.capacity_type) == "SPOT"
    tags              = ["zilliz-byoc", each.key]
    oauth_scopes      = ["https://www.googleapis.com/auth/cloud-platform"]
    boot_disk_kms_key = local.effective_boot_disk_kms_key_name != "" ? local.effective_boot_disk_kms_key_name : null

    dynamic "boot_disk" {
      for_each = try(var.node_group_disk_overrides[each.key].provisioned_iops, null) != null || try(var.node_group_disk_overrides[each.key].provisioned_throughput, null) != null ? [var.node_group_disk_overrides[each.key]] : []
      content {
        disk_type              = boot_disk.value.disk_type
        size_gb                = boot_disk.value.disk_size_gb
        provisioned_iops       = boot_disk.value.provisioned_iops
        provisioned_throughput = boot_disk.value.provisioned_throughput
      }
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

    dynamic "ephemeral_storage_local_ssd_config" {
      for_each = contains(keys(local.node_group_local_ssd_counts), each.key) ? [local.node_group_local_ssd_counts[each.key]] : []
      content {
        local_ssd_count = ephemeral_storage_local_ssd_config.value
      }
    }

    dynamic "linux_node_config" {
      for_each = each.key == "search" ? [1] : []
      content {
        sysctls = {
          "net.core.somaxconn" = "4096"
          "net.ipv4.tcp_rmem"  = "4096 131072 6291456"
          "net.ipv4.tcp_wmem"  = "4096 20480 4194304"
        }
      }
    }

    shielded_instance_config {
      enable_integrity_monitoring = var.node_enable_integrity_monitoring
      enable_secure_boot          = var.node_enable_secure_boot
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }

  lifecycle {
    ignore_changes = [initial_node_count]
    precondition {
      condition     = !startswith(each.value.instance_types, "n2-") || local.node_group_disk_types[each.key] != "hyperdisk-balanced"
      error_message = "N2 pool ${each.key} cannot use hyperdisk-balanced as a boot disk; choose pd-balanced/pd-ssd or a compatible machine."
    }
    precondition {
      condition     = !startswith(each.value.instance_types, "n4-") || local.node_group_disk_types[each.key] == "hyperdisk-balanced"
      error_message = "N4 pool ${each.key} requires a hyperdisk-balanced boot disk; set node_group_disk_overrides for this pool."
    }
    precondition {
      condition     = upper(var.release_channel) == "UNSPECIFIED" || var.node_auto_upgrade
      error_message = "Opt into node_auto_upgrade when selecting a release channel."
    }
    precondition {
      condition     = var.boot_disk_kms_key_name == "" || try(split("/", var.boot_disk_kms_key_name)[3] == var.gcp_region, false)
      error_message = "Boot disk KMS key must be in the GKE region."
    }
  }

  depends_on = [terraform_data.existing_cluster_validation]
}
