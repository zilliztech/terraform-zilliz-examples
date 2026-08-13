moved {
  from = google_compute_network.this
  to   = google_compute_network.this[0]
}

moved {
  from = google_compute_subnetwork.primary
  to   = google_compute_subnetwork.primary[0]
}

moved {
  from = google_compute_subnetwork.lb
  to   = google_compute_subnetwork.lb[0]
}

moved {
  from = google_compute_router.this
  to   = google_compute_router.this[0]
}

moved {
  from = google_compute_address.nat
  to   = google_compute_address.nat[0]
}

moved {
  from = google_compute_router_nat.this
  to   = google_compute_router_nat.this[0]
}

moved {
  from = google_compute_firewall.allow_health_check
  to   = google_compute_firewall.allow_health_check[0]
}

moved {
  from = google_compute_firewall.allow_local
  to   = google_compute_firewall.allow_local[0]
}
