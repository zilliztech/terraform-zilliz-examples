terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0.0"
    }
    zillizcloud = {
      source  = "zilliztech/zillizcloud"
      version = "0.6.26-rc2"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "38fd913c-a183-459a-b857-1c23940d70c1"
}

provider "azapi" {
}

