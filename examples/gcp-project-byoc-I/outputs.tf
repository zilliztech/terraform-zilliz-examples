output "project_id" {
  value = local.project_id
}

output "data_plane_id" {
  value = local.data_plane_id
}

output "gke_cluster_name" {
  value = local.gke_cluster_name
}

output "gcs_bucket_id" {
  value = module.gcs.bucket_id
}

output "gcs_kms_key_name" {
  value = module.gcs.kms_key_name
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

output "booter_sa" {
  value = module.iam.booter_sa_email
}

output "booter_vm_name" {
  value = try(module.booter_vm[0].instance_name, null)
}

output "vpc_cidr" {
  value = local.is_existing_network ? null : var.vpc_cidr
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

output "master_ipv4_cidr_block" {
  value = local.master_ipv4_cidr_block
}

output "psc_endpoint_ip" {
  value = local.psc_endpoint_ip
}
