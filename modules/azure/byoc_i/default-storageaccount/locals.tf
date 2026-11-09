data "azurerm_location" "current" {
  location = var.location
}

locals {
  customer_managed_key = var.enable_cmk_sse ? var.customer_managed_key : null

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

