output "byoc_endpoint_id" {
  value = google_compute_forwarding_rule.byoc_endpoint.id
}

output "byoc_endpoint_ip" {
  value = google_compute_address.psc.address
}

output "private_dns_zone_name" {
  value = try(google_dns_managed_zone.psc[0].name, null)
}

output "private_dns_record_names" {
  value = [for record in google_dns_record_set.psc : record.name]
}
