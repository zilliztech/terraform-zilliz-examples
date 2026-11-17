data "zillizcloud_byoc_vpc_endpoint_service" "this" {
  count = local.enable_private_link && local.configured_privatelink_resource_alias == "" ? 1 : 0

  cloud_id = "azure"
  region   = local.location
}
