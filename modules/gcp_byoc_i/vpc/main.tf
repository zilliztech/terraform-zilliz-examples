resource "google_compute_network" "this" {
  count = local.create_vpc ? 1 : 0

  project                                   = var.network_project_id
  name                                      = local.vpc_name
  routing_mode                              = "REGIONAL"
  auto_create_subnetworks                   = false
  mtu                                       = 1460
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
}

resource "google_compute_subnetwork" "primary" {
  count = local.create_primary_subnet ? 1 : 0

  project                  = var.network_project_id
  name                     = local.primary_subnet_name
  ip_cidr_range            = local.created_primary_subnet_cidr
  region                   = var.gcp_region
  network                  = local.vpc.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = local.pod_subnet_name
    ip_cidr_range = local.created_pod_subnet_cidr
  }

  secondary_ip_range {
    range_name    = local.service_subnet_name
    ip_cidr_range = local.created_service_subnet_cidr
  }
}

resource "google_compute_subnetwork" "lb" {
  count = local.create_lb_subnet ? 1 : 0

  project       = var.network_project_id
  name          = local.lb_subnet_name
  ip_cidr_range = local.created_lb_subnet_cidr
  region        = var.gcp_region
  network       = local.vpc.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}
