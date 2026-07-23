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
  value = var.vpc_cidr
}

output "primary_subnet_cidr" {
  value = module.vpc.primary_subnet_cidr
}

output "pod_subnet_cidr" {
  value = module.vpc.pod_subnet_cidr
}

output "service_subnet_cidr" {
  value = module.vpc.service_subnet_cidr
}

output "lb_subnet_cidr" {
  value = module.vpc.lb_subnet_cidr
}

output "master_ipv4_cidr_block" {
  value = var.master_ipv4_cidr_block
}

output "psc_endpoint_ip" {
  value = local.psc_endpoint_ip
}
