data "google_compute_network" "this" {
  name = var.vpc_name
}

data "google_compute_subnetwork" "this" {
  name   = var.subnet_name
  region = var.gcp_region
}

resource "google_compute_address" "psc" {
  name         = "${var.prefix_name}-psc-ip"
  region       = var.gcp_region
  subnetwork   = data.google_compute_subnetwork.this.id
  address_type = "INTERNAL"
}

resource "google_compute_forwarding_rule" "byoc_endpoint" {
  name                    = "${var.prefix_name}-byoc-endpoint"
  region                  = var.gcp_region
  load_balancing_scheme   = ""
  network                 = data.google_compute_network.this.id
  ip_address              = google_compute_address.psc.id
  allow_psc_global_access = false
  target                  = local.service_attachment_id

  lifecycle {
    precondition {
      condition     = local.service_attachment_id != ""
      error_message = "Set service_attachment_id or add modules/conf.yaml GCP.private_service_connect.service_attachment_ids for this region."
    }
  }
}
