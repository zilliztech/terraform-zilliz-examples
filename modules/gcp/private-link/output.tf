output "byoc_endpoint_id" {
    value = google_compute_forwarding_rule.byoc_endpoint.id
}

output "byoc_endpoint_ip" {
    value = google_compute_address.psc_ip.address
}
