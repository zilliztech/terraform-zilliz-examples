resource "google_container_cluster" "this" {
  project                  = var.gcp_project_id
  name                     = var.cluster_name
  location                 = var.gcp_region
  min_master_version       = var.kubernetes_version
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = var.network_self_link
  subnetwork               = var.primary_subnet_self_link
  networking_mode          = "VPC_NATIVE"
  node_locations           = var.gcp_zones
  deletion_protection      = var.deletion_protection
  resource_labels          = local.common_labels

  logging_service    = "none"
  monitoring_service = "none"

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

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pod_subnet_name
    services_secondary_range_name = var.service_subnet_name
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
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block

    master_global_access_config {
      enabled = true
    }
  }

  release_channel {
    channel = "UNSPECIFIED"
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "this" {
  for_each = local.node_groups

  project            = var.gcp_project_id
  name               = each.key
  location           = var.gcp_region
  cluster            = google_container_cluster.this.name
  node_locations     = var.gcp_zones
  initial_node_count = max(each.value.desired_size, each.value.min_size)
  max_pods_per_node  = each.key == "core" ? 110 : 32

  autoscaling {
    location_policy      = "ANY"
    total_min_node_count = each.value.min_size
    total_max_node_count = each.value.max_size
  }

  management {
    auto_repair  = true
    auto_upgrade = false
  }

  network_config {
    create_pod_range     = false
    enable_private_nodes = true
    pod_range            = var.pod_subnet_name
  }

  node_config {
    disk_size_gb    = max(each.value.disk_size, 100)
    disk_type       = "pd-balanced"
    image_type      = "COS_CONTAINERD"
    labels          = local.node_group_labels[each.key]
    machine_type    = each.value.instance_types
    preemptible     = false
    service_account = var.gke_node_sa_email
    spot            = upper(each.value.capacity_type) == "SPOT"
    tags            = ["zilliz-byoc", each.key]
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    dynamic "ephemeral_storage_local_ssd_config" {
      for_each = each.key == "search" ? [1] : []
      content {
        local_ssd_count = 4
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
      enable_integrity_monitoring = true
      enable_secure_boot          = false
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
  }
}
