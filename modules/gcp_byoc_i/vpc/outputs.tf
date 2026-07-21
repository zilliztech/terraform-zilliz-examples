output "vpc_name" {
  value = google_compute_network.this.name
}

output "vpc_id" {
  value = google_compute_network.this.id
}

output "vpc_self_link" {
  value = google_compute_network.this.self_link
}

output "primary_subnet_name" {
  value = google_compute_subnetwork.primary.name
}

output "primary_subnet_id" {
  value = google_compute_subnetwork.primary.id
}

output "primary_subnet_self_link" {
  value = google_compute_subnetwork.primary.self_link
}

output "primary_subnet_cidr" {
  value = local.primary_subnet_cidr
}

output "pod_subnet_cidr" {
  value = local.pod_subnet_cidr
}

output "service_subnet_cidr" {
  value = local.service_subnet_cidr
}

output "lb_subnet_cidr" {
  value = local.lb_subnet_cidr
}

output "pod_subnet_name" {
  value = local.pod_subnet_name
}

output "service_subnet_name" {
  value = local.service_subnet_name
}

output "lb_subnet_name" {
  value = google_compute_subnetwork.lb.name
}

output "nat_ip" {
  value = google_compute_address.nat.address
}
