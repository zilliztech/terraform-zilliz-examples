resource "google_compute_firewall" "allow_health_check" {
  count = var.create_firewall_rules ? 1 : 0

  project       = var.network_project_id
  name          = "${local.firewall_name_prefix}-allow-health-check"
  network       = local.vpc.name
  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["zilliz-byoc"]

  allow {
    protocol = "tcp"
    ports    = ["19530"]
  }
}

resource "google_compute_firewall" "allow_local" {
  count = var.create_firewall_rules ? 1 : 0

  project       = var.network_project_id
  name          = "${local.firewall_name_prefix}-allow-local"
  network       = local.vpc.name
  direction     = "INGRESS"
  source_ranges = local.internal_source_ranges
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
