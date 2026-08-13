output "network_project_id" {
  value = var.network_project_id
}

output "is_shared_vpc" {
  value = var.network_project_id != var.gcp_project_id
}

output "vpc_name" {
  value = local.vpc.name
}

output "vpc_id" {
  value = local.vpc.id
}

output "vpc_self_link" {
  value = local.vpc.self_link
}

output "primary_subnet_name" {
  value = local.primary_subnet.name
}

output "primary_subnet_id" {
  value = local.primary_subnet.id
}

output "primary_subnet_self_link" {
  value = local.primary_subnet.self_link
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
  value = local.lb_subnet.name
}

output "nat_ip" {
  value = try(google_compute_address.nat[0].address, null)
}
