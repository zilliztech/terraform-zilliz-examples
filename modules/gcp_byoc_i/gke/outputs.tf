output "cluster_name" {
  value = local.cluster.name
}

output "cluster_id" {
  value = local.cluster.id
}

output "cluster_location" {
  value = local.cluster.location
}

output "private_endpoint" {
  value = try(local.cluster.private_cluster_config[0].private_endpoint, null)
}

output "node_pool_names" {
  value = keys(google_container_node_pool.this)
}

output "secrets_kms_key_name" {
  value = local.effective_secrets_kms_key_name
}
