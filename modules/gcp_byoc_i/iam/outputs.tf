output "gke_node_sa_email" {
  value = local.gke_node_sa.email
}

output "management_sa_email" {
  value = local.management_sa.email
}

output "storage_sa_email" {
  value = local.storage_sa.email
}

output "booter_sa_email" {
  value = local.booter_sa.email
}
