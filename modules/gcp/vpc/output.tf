output "region" {
  value = var.gcp_region
}

output "gcp_vpc_name" {
  value = google_compute_network.gcp_vpc.name
}

output "zones" {
  value = local.azs
}

output "primary_subnet_name" {
  value = google_compute_subnetwork.gcp_vpc_subnet.name
}

output "load_balancer_subnet_name" {
  value = google_compute_subnetwork.lb_subnet.name
}


output "secondary_subnet_range_name_pods" {
  value = local.pod_subnet_name
}

output "secondary_subnet_range_name_services" {
  value = local.service_subnet_name
}