output "endpoint_id" {
  value = aws_vpc_endpoint.byoc_endpoint[0].id
}
