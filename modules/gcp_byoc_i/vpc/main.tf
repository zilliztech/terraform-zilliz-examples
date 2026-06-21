resource "google_compute_network" "this" {
  name                                      = local.vpc_name
  routing_mode                              = "REGIONAL"
  auto_create_subnetworks                   = false
  mtu                                       = 1460
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
}

resource "google_compute_subnetwork" "primary" {
  name                     = local.primary_subnet_name
  ip_cidr_range            = local.primary_subnet_cidr
  region                   = var.gcp_region
  network                  = google_compute_network.this.id
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

resource "google_compute_subnetwork" "lb" {
  name          = local.lb_subnet_name
  ip_cidr_range = local.lb_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.this.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_router" "this" {
  name    = local.router_name
  region  = var.gcp_region
  network = google_compute_network.this.id
}

resource "google_compute_address" "nat" {
  name         = "${local.nat_name}-ip"
  region       = var.gcp_region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

resource "google_compute_router_nat" "this" {
  name   = local.nat_name
  router = google_compute_router.this.name
  region = var.gcp_region

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat.self_link]

  subnetwork {
    name                    = google_compute_subnetwork.primary.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_firewall" "allow_health_check" {
  name          = "${local.vpc_name}-allow-health-check"
  network       = google_compute_network.this.name
  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["zilliz-byoc"]

  allow {
    protocol = "tcp"
    ports    = ["19530"]
  }
}

resource "google_compute_firewall" "allow_local" {
  name          = "${local.vpc_name}-allow-local"
  network       = google_compute_network.this.name
  direction     = "INGRESS"
  source_ranges = [var.vpc_cidr]
  target_tags   = ["zilliz-byoc"]

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }
}
