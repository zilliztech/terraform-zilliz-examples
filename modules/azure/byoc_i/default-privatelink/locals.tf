data "azurerm_location" "current" {
  location = var.location
}

locals {
  # Convert location display name to short name using Azure data source
  location = data.azurerm_location.current.location

  # Standard tags for all resources
  common_tags = merge(
    {
      "Vendor" = "zilliz-byoc"
    },
    var.custom_tags
  )

  config = yamldecode(file("${path.module}/../../../conf.yaml"))

  dns_zone_name = "cloud-tunnel.az-${local.location}.${local.config.Azure.private_zone_domain_suffix}"

  zilliz_byoc_privatelink_resource_alias = local.config.Azure.zilliz_byoc_privatelink_resource_alias["${local.location}"]
}