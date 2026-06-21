output "cluster_name" {
  value = google_container_cluster.this.name
}

output "cluster_id" {
  value = google_container_cluster.this.id
}

output "cluster_location" {
  value = google_container_cluster.this.location
}

output "private_endpoint" {
  value = google_container_cluster.this.private_cluster_config[0].private_endpoint
}

output "node_pool_names" {
  value = keys(google_container_node_pool.this)
}
