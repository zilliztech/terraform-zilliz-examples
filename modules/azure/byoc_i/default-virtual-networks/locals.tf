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
}

