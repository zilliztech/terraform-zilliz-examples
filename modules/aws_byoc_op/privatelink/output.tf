output "endpoint_id" {
  value = var.enable_private_link ?aws_vpc_endpoint.byoc_endpoint[0].id: null
}
