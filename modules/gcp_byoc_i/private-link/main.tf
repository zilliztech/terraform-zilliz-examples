resource "google_compute_address" "psc" {
  project      = var.gcp_project_id
  name         = "${var.prefix_name}-psc-ip"
  region       = var.gcp_region
  subnetwork   = var.subnet_self_link
  address_type = "INTERNAL"
}

resource "google_compute_forwarding_rule" "byoc_endpoint" {
  project                 = var.gcp_project_id
  name                    = "${var.prefix_name}-byoc-endpoint"
  region                  = var.gcp_region
  load_balancing_scheme   = ""
  network                 = var.vpc_self_link
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

resource "google_dns_managed_zone" "psc" {
  count = var.enable_private_dns && local.private_dns_domain != "" ? 1 : 0

  project     = var.network_project_id
  name        = local.private_dns_zone_name
  dns_name    = local.private_dns_domain
  description = "Private DNS zone for Zilliz BYOC Private Service Connect hosts."
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = var.vpc_self_link
    }
  }
}

resource "google_dns_record_set" "psc" {
  for_each = var.enable_private_dns && local.private_dns_domain != "" ? toset(var.private_dns_record_names) : toset([])

  project      = var.network_project_id
  name         = endswith(each.value, ".") ? each.value : "${each.value}."
  managed_zone = google_dns_managed_zone.psc[0].name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_address.psc.address]
}
