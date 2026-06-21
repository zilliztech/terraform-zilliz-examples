output "project_id" {
  value = local.project_id
}

output "data_plane_id" {
  value = local.data_plane_id
}

output "gke_cluster_name" {
  value = module.gke.cluster_name
}

output "gcs_bucket_id" {
  value = module.gcs.bucket_id
}

output "management_sa" {
  value = module.iam.management_sa_email
}

output "storage_sa" {
  value = module.iam.storage_sa_email
}

output "gke_node_sa" {
  value = module.iam.gke_node_sa_email
}

output "booter_vm_name" {
  value = module.booter_vm.instance_name
}

output "psc_endpoint_ip" {
  value = local.psc_endpoint_ip
}
