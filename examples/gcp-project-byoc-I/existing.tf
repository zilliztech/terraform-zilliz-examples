data "google_compute_network" "existing" {
  count = local.is_existing_network ? 1 : 0

  project = var.existing_network.network_project_id
  name    = var.existing_network.vpc_name
}

data "google_compute_subnetwork" "existing_primary" {
  count = local.is_existing_network ? 1 : 0

  project = var.existing_network.network_project_id
  region  = local.gcp_region
  name    = var.existing_network.primary_subnet_name
}

data "google_compute_subnetwork" "existing_lb" {
  count = local.is_existing_network ? 1 : 0

  project = var.existing_network.network_project_id
  region  = local.gcp_region
  name    = var.existing_network.lb_subnet_name
}

data "google_container_cluster" "existing" {
  count = local.is_existing_gke ? 1 : 0

  project  = var.gcp_project_id
  location = local.gcp_region
  name     = var.existing_gke.cluster_name
}

resource "terraform_data" "existing_infrastructure_validation" {
  input = {
    existing_network = local.is_existing_network
    existing_gke     = local.is_existing_gke
  }

  lifecycle {
    precondition {
      condition     = !local.is_existing_gke || local.is_existing_network
      error_message = "existing_gke requires existing_network because an existing GKE cluster cannot use the VPC created by this configuration."
    }

    precondition {
      condition = local.is_existing_network ? (
        basename(data.google_compute_subnetwork.existing_primary[0].network) == data.google_compute_network.existing[0].name &&
        basename(data.google_compute_subnetwork.existing_lb[0].network) == data.google_compute_network.existing[0].name
      ) : true
      error_message = "The existing primary and load-balancer subnets must belong to existing_network.vpc_name."
    }

    precondition {
      condition = local.is_existing_network ? (
        contains(keys(local.existing_primary_secondary_ranges), var.existing_network.pod_secondary_range_name) &&
        contains(keys(local.existing_primary_secondary_ranges), var.existing_network.service_secondary_range_name)
      ) : true
      error_message = "The existing primary subnet must contain the configured pod and service secondary ranges."
    }

    precondition {
      condition = local.is_existing_gke && local.is_existing_network ? (
        data.google_container_cluster.existing[0].location == local.gcp_region &&
        length(data.google_container_cluster.existing[0].node_locations) > 0 &&
        basename(data.google_container_cluster.existing[0].network) == data.google_compute_network.existing[0].name &&
        basename(data.google_container_cluster.existing[0].subnetwork) == data.google_compute_subnetwork.existing_primary[0].name
      ) : true
      error_message = "The existing GKE cluster must be regional, in the BYOC-I region, and attached to the configured Shared VPC primary subnet."
    }

    precondition {
      condition = local.is_existing_gke ? (
        data.google_container_cluster.existing[0].networking_mode == "VPC_NATIVE" &&
        try(data.google_container_cluster.existing[0].private_cluster_config[0].enable_private_nodes, false) &&
        try(data.google_container_cluster.existing[0].private_cluster_config[0].enable_private_endpoint, false) &&
        try(data.google_container_cluster.existing[0].workload_identity_config[0].workload_pool, "") == "${var.gcp_project_id}.svc.id.goog"
      ) : true
      error_message = "The existing GKE cluster must be VPC-native, use private nodes and a private endpoint, and enable Workload Identity for the service project."
    }

    precondition {
      condition = local.is_existing_gke && local.is_existing_network ? (
        try(data.google_container_cluster.existing[0].ip_allocation_policy[0].cluster_secondary_range_name, "") == var.existing_network.pod_secondary_range_name &&
        try(data.google_container_cluster.existing[0].ip_allocation_policy[0].services_secondary_range_name, "") == var.existing_network.service_secondary_range_name
      ) : true
      error_message = "The existing GKE cluster must use the configured pod and service secondary ranges."
    }

    precondition {
      condition = local.is_existing_gke ? length(setsubtract(
        local.required_node_pool_names,
        toset(keys(local.existing_node_pools)),
      )) == 0 : true
      error_message = "The existing GKE cluster is missing required BYOC-I node pools: ${join(", ", sort(tolist(setsubtract(local.required_node_pool_names, toset(keys(local.existing_node_pools))))))}. Required pool names are derived from the Zilliz BYOC-I project quota."
    }

    precondition {
      condition = local.is_existing_gke ? alltrue([
        for node_pool_name in local.required_node_pool_names :
        try(local.existing_node_pools[node_pool_name].node_config[0].service_account, "") == var.existing_gke.node_service_account_email
      ]) : true
      error_message = "All required existing GKE node pools must use existing_gke.node_service_account_email."
    }

    precondition {
      condition = local.is_existing_gke ? alltrue(flatten([
        for node_pool_name in local.required_node_pool_names : [
          for label_name, label_value in local.required_node_pool_labels[node_pool_name] :
          try(local.existing_node_pools[node_pool_name].node_config[0].labels[label_name], "") == label_value
        ]
      ])) : true
      error_message = "The existing GKE node pools do not contain all required Zilliz BYOC-I node labels."
    }
  }
}
