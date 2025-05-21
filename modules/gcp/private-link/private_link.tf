data "google_compute_network" "psc_vpc" {
   name    = var.gcp_vpc_name
}

data "google_compute_subnetwork" "psc_subnet" {
   name     = var.service_subnet_name
   region   = var.gcp_region
}

// create a private IP address for the PSC
resource "google_compute_address" "psc_ip" {
    name = "${var.prefix_name}-psc-ip"
    region = var.gcp_region
    subnetwork = data.google_compute_subnetwork.psc_subnet.id
    address_type = "INTERNAL"
}

// create a forwarding rule to the BYOC endpoint
resource "google_compute_forwarding_rule" "byoc_endpoint" {
    name                    = "${var.prefix_name}-byoc-endpoint"
    region                  = var.gcp_region

    load_balancing_scheme   = ""
    network                 = data.google_compute_network.psc_vpc.id
    ip_address              = google_compute_address.psc_ip.id
    allow_psc_global_access = false

    target                  = local.config.service_attachment_ids[var.gcp_region]
}