terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80, < 5.3"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.15, < 3.0"
    }
  }
}
