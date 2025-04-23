output "region" {
  value = var.gcp_region
}

output "gcp_vpc_name" {
  value = google_compute_network.gcp_vpc.name
}

output "zones" {
  value = local.azs
}

output "gcp_subnetwork_name" {
  value = google_compute_subnetwork.gcp_vpc_subnet.name
}

output "gcp_lb_subnet_name" {
  value = google_compute_subnetwork.lb_subnet.name
}

output "gcp_nat_ip" {
  value = google_compute_address.nat.address
}