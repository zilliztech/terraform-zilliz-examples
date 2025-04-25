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

// create a private zone
resource "google_dns_managed_zone" "byoc_endpoint_private_zone" {
    name = "${var.prefix_name}-byoc-private-zone"
    dns_name = "zilliz-byoc-${substr(var.gcp_region, 0, 2)}.${local.config.private_zone_dns_name_suffix}"
    visibility = "private"
    private_visibility_config {
        networks {
            network_url = data.google_compute_network.psc_vpc.id
        }
    }
}

// create a zone record that points to the byoc endpoint
resource "google_dns_record_set" "byoc_endpoint_private_zone_record" {
    name = google_dns_managed_zone.byoc_endpoint_private_zone.dns_name
    type = "A"
    ttl = 300
    managed_zone = google_dns_managed_zone.byoc_endpoint_private_zone.name
    rrdatas = [google_compute_address.psc_ip.address]
}