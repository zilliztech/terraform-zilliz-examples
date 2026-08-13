resource "google_compute_router" "this" {
  count = var.create_cloud_nat ? 1 : 0

  project = var.network_project_id
  name    = local.router_name
  region  = var.gcp_region
  network = local.vpc.id
}

resource "google_compute_address" "nat" {
  count = var.create_cloud_nat ? 1 : 0

  project      = var.network_project_id
  name         = "${local.nat_name}-ip"
  region       = var.gcp_region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

resource "google_compute_router_nat" "this" {
  count = var.create_cloud_nat ? 1 : 0

  project                            = var.network_project_id
  name                               = local.nat_name
  router                             = google_compute_router.this[0].name
  region                             = var.gcp_region
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat[0].self_link]

  subnetwork {
    name                    = local.primary_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
