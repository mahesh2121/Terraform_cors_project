terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80, < 5.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.15, < 3.0"
    }
  }

  # Remote state in an Azure Storage container (partial configuration).
  # Initialize with: terraform init -backend-config=backend.azurerm.hcl
  # See backend.azurerm.hcl.example.
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

module "webapp_cors" {
  source = "../../modules/azure-webapp-cors"

  name                  = var.app_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  create_resource_group = true

  sku_name             = var.sku_name
  application_stack    = var.application_stack
  app_settings         = var.app_settings
  cors_allowed_origins = var.cors_allowed_origins

  tags = var.tags
}
