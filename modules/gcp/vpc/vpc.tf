# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network
resource "google_compute_network" "gcp_vpc" {
  name                            = var.gcp_vpc_name
  routing_mode                    = "REGIONAL"
  auto_create_subnetworks         = false
  mtu                             = 1460
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  delete_default_routes_on_create = false

}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork
resource "google_compute_subnetwork" "gcp_vpc_subnet" {
  name                     = local.primary_subnet_name
  ip_cidr_range            = local.primary_subnet_cidr
  region                   = var.gcp_region
  network                  = google_compute_network.gcp_vpc.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = local.pod_subnet_name
    ip_cidr_range = local.pod_subnet_cidr
  }
  secondary_ip_range {
    range_name    = local.service_subnet_name
    ip_cidr_range = local.service_subnet_cidr
  }
}

resource "google_compute_subnetwork" "lb_subnet" {
  name                     = local.lb_subnet_name
  ip_cidr_range            = local.lb_subnet_cidr
  region                   = var.gcp_region
  network                  = google_compute_network.gcp_vpc.id
  purpose                  = "REGIONAL_MANAGED_PROXY"
  role                     = "ACTIVE"
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router
resource "google_compute_router" "router" {
  name    = local.router_name
  region  = var.gcp_region
  network = google_compute_network.gcp_vpc.id
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat
resource "google_compute_router_nat" "nat" {
  name   = local.nat_name
  router = google_compute_router.router.name
  region = var.gcp_region

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ip_allocate_option             = "MANUAL_ONLY"

  subnetwork {
    name                    = google_compute_subnetwork.gcp_vpc_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  nat_ips = [google_compute_address.nat.self_link]
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address
resource "google_compute_address" "nat" {
  name         = "${local.nat_name}-ip"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

# https://cloud.google.com/load-balancing/docs/health-check-concepts#ip-ranges
resource "google_compute_firewall" "fw-allow-health-check" {
  name    = "${var.gcp_vpc_name}-fw-allow-health-check"
  network = google_compute_network.gcp_vpc.name
  direction = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]

  allow {
    protocol = "tcp"
    ports    = ["19530"]
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall
resource "google_compute_firewall" "fw-allow-local" {
  name    = "${var.gcp_vpc_name}-fw-allow-local"
  network = google_compute_network.gcp_vpc.name
  direction = "INGRESS"
  source_ranges = [var.gcp_vpc_cidr]
  target_tags = ["zilliz-byoc"]

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
}
