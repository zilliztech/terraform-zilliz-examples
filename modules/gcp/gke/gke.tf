# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster
resource "google_container_cluster" "gke_cluster" {
  name                        = var.k8s_short_cluster_name
  location                    = var.gcp_region
  remove_default_node_pool    = true
  initial_node_count          = 1
  network                     = "projects/${var.gcp_project_id}/global/networks/${var.gcp_vpc_name}"
  subnetwork                  = "projects/${var.gcp_project_id}/regions/${var.gcp_region}/subnetworks/${var.gcp_subnetwork_name}"
  logging_service             = "none"
  monitoring_service          = "none"
  networking_mode             = "VPC_NATIVE"
  node_locations              = var.gcp_zones
  # for terraform destroy
  deletion_protection         = false
  resource_labels             = {
    terraform                 = true
    vendor                    = "zilliz-byoc"
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
  binary_authorization {
    evaluation_mode = "DISABLED"
  }
  cluster_autoscaling {
    autoscaling_profile = "BALANCED"
    enabled             = false
  }
  database_encryption {
    key_name = null
    state    = "DECRYPTED"
  }
  default_snat_status {
    disabled = true
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pod_subnet_range_name
    services_secondary_range_name = var.service_subnet_range_name
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = true
    
    dynamic "cidr_blocks" {
      for_each = var.k8s_access_cidrs
      content {
        cidr_block   = cidr_blocks.value
        display_name = "access-cidr-${cidr_blocks.key}"
      }
    }
  }
  network_policy {
    enabled  = false
    provider = "PROVIDER_UNSPECIFIED"
  }

  notification_config {
    pubsub {
      enabled = false
      topic   = null
    }
  }
  private_cluster_config {
    enable_private_endpoint     = false
    enable_private_nodes        = false
    private_endpoint_subnetwork = null
    master_global_access_config {
      enabled = true
    }
  }
  release_channel {
    channel = "UNSPECIFIED"
  }
  service_external_ips_config {
    enabled = false
  }
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account
data "google_service_account" "zilliz-byoc-client-sa" {
  account_id = var.biz_sa_email
}

resource "google_container_node_pool" "fundamentals" {
  project = var.gcp_project_id
  name    = "fundamentals"
  cluster = google_container_cluster.gke_cluster.id
  max_pods_per_node  = 32

  management {
    auto_repair  = true
    auto_upgrade = false
  }
  network_config {
    create_pod_range     = false
    enable_private_nodes = true
    pod_range            = "${var.pod_subnet_range_name}"
  }
  autoscaling {
    location_policy      = "ANY"
    total_max_node_count       = var.k8s_node_groups.fundamentals.max_size
    total_min_node_count       = var.k8s_node_groups.fundamentals.min_size
  }

  node_config {
    boot_disk_kms_key = null
    disk_size_gb      = 100
    disk_type         = "pd-balanced"
    image_type        = "COS_CONTAINERD"
    labels = {
       "zilliz-group-name" = "fundamental"
        "node-role/default" = "true"
        "node-role/milvus"  = "true"
    }
    local_ssd_count = 0
    logging_variant = "DEFAULT"
    machine_type    = var.k8s_node_groups.fundamentals.instance_types
    metadata = {
      disable-legacy-endpoints = "true"
    }
    min_cpu_platform      = null
    node_group            = null
    oauth_scopes          = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
    preemptible           = false
    service_account       = var.biz_sa_email
    spot                  = false
    tags                  = ["zilliz-byoc", "fundamentals"]
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
}

resource "google_container_node_pool" "index" {
  project = var.gcp_project_id
  cluster = google_container_cluster.gke_cluster.id
  max_pods_per_node  = 32
  name               = "index"
  name_prefix        = null
  autoscaling {
    location_policy      = "ANY"
    total_max_node_count = var.k8s_node_groups.index.max_size
    total_min_node_count = var.k8s_node_groups.index.min_size
  }
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  network_config {
    create_pod_range     = false
    enable_private_nodes = true
    pod_range            = "${var.pod_subnet_range_name}"
  }
  node_config {
    boot_disk_kms_key = null
    disk_size_gb      = 100
    disk_type         = "pd-balanced"
    image_type        = "COS_CONTAINERD"
    labels = {
      "zilliz-group-name"    = "index"
      "node-role/index-pool" = "true"
    }
    local_ssd_count = 0
    logging_variant = "DEFAULT"
    machine_type    = var.k8s_node_groups.index.instance_types
    metadata = {
      disable-legacy-endpoints = "true"
    }
    min_cpu_platform      = null
    node_group            = null
    oauth_scopes          = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
    preemptible           = false
    service_account       = var.biz_sa_email
    spot                  = false
    tags                  = ["zilliz-byoc","index-pool"]
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
}

resource "google_container_node_pool" "core" { 
  project = var.gcp_project_id
  max_pods_per_node  = 32
  name               = "core"
  name_prefix        = null
  cluster = google_container_cluster.gke_cluster.id
  autoscaling {
    location_policy      = "ANY"
    total_max_node_count = var.k8s_node_groups.core.max_size
    total_min_node_count = var.k8s_node_groups.core.min_size
  }
  management {
    auto_repair  = true
    auto_upgrade = false
  }
  network_config {
    create_pod_range     = false
    enable_private_nodes = true
    pod_range            = "${var.pod_subnet_range_name}"
  }
  node_config {
    boot_disk_kms_key = null
    disk_size_gb      = 200
    disk_type         = "pd-balanced"
    image_type        = "COS_CONTAINERD"
    labels = {
    "zilliz-group-name"     = "core"
    "node-role/etcd"        = "true"
    "node-role/pulsar"      = "true"
    "node-role/infra"       = "true",
    "node-role/vdc"         = "true",
    "node-role/milvus-tool" = "true",
    "capacity-type"         = "ON_DEMAND"
    }
    local_ssd_count = 0
    logging_variant = "DEFAULT"
    machine_type    = var.k8s_node_groups.core.instance_types
    metadata = {
      disable-legacy-endpoints = "true"
    }
    min_cpu_platform      = "Intel Ice Lake"
    node_group            = null
    oauth_scopes          = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
    preemptible           = false
    service_account       = var.biz_sa_email
    spot                  = false
    tags                  = ["zilliz-byoc","core"]
    linux_node_config {
      cgroup_mode = null
      sysctls = {
        "net.core.somaxconn" = "4096"
        "net.ipv4.tcp_rmem"  = "4096 131072  6291456"
        "net.ipv4.tcp_wmem"  = "4096 20480  4194304"
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

}

resource "google_container_node_pool" "search" { 
  project = var.gcp_project_id
  cluster = google_container_cluster.gke_cluster.id
  # initial_node_count = var.k8s_node_groups.search.desired_size
  max_pods_per_node  = 110
  name               = "search"
  name_prefix        = null
  autoscaling {
    location_policy      = "ANY"
    total_max_node_count = var.k8s_node_groups.search.max_size
    total_min_node_count = var.k8s_node_groups.search.min_size
  }
  management {
    auto_repair  = true
    auto_upgrade = false
  }
  network_config {
    create_pod_range     = false
    enable_private_nodes = true
    pod_range            = "${var.pod_subnet_range_name}"
  }
  node_config {
    boot_disk_kms_key = null
    disk_size_gb      = 100
    disk_type         = "pd-balanced"
    image_type        = "COS_CONTAINERD"
    labels = {
    "zilliz-group-name"    = "search"
    "node-role/diskANN"    = "true"
    "node-role/milvus"     = "true"
    "node-role/nvme-quota" = "200"
    }

    local_ssd_count = 0
    ephemeral_storage_local_ssd_config {
      local_ssd_count = 4
    }
    logging_variant = "DEFAULT"
    machine_type    = var.k8s_node_groups.search.instance_types
    metadata = {
      disable-legacy-endpoints = "true"
    }
    min_cpu_platform      = null
    node_group            = null
    oauth_scopes          = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
    preemptible           = false
    service_account       = var.biz_sa_email
    spot                  = false
    tags                  = ["zilliz-byoc","search"]
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
}
