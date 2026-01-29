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

  # Identity name
  storage_identity_name = "${var.name}-storage-identity"

  # Instance identities set (1-9) - must be strings for for_each
  # range(1, 10) generates [1,2,3,4,5,6,7,8,9] = 9 elements
  instance_identities = toset([for i in range(1, 10) : tostring(i)])
}

