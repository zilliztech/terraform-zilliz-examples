
output "network_settings" {
  value = module.vpc
}

output "credential_settings" {
  value = module.iam
}

output "private_service_connection" {
  value = var.enable_private_link ? module.private_link[0].byoc_endpoint_ip : null
}

output "bucket_name" {
  value = local.bucket_name
}


