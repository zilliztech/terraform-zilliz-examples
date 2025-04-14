locals {
  bucket_name = length(var.customer_bucket_name) > 0 ? var.customer_bucket_name: "${var.dataplane_id}-milvus"
}