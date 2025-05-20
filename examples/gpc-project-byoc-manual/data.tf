//random id
resource "random_id" "short_uuid" {
  byte_length = 3 # 3 bytes = 6 characters when base64 encoded
}
locals {
  bucket_name                              = var.customer_bucket_name != "" ? var.customer_bucket_name : "${var.customer_vpc_name}-bucket-${random_id.short_uuid.hex}"
  prefix_name                              = var.customer_vpc_name
  customer_gke_cluster_name                = var.customer_gke_cluster_name != "" ? var.customer_gke_cluster_name : "${var.customer_vpc_name}-gke"
  customer_storage_service_account_name    = var.customer_storage_service_account_name != "" ? var.customer_storage_service_account_name : "${var.customer_vpc_name}-storage-sa"
  customer_management_service_account_name = var.customer_management_service_account_name != "" ? var.customer_management_service_account_name : "${var.customer_vpc_name}-management-sa"
  customer_gke_node_service_account_name   = var.customer_gke_node_service_account_name != "" ? var.customer_gke_node_service_account_name : "${var.customer_vpc_name}-gke-node-sa"
}
