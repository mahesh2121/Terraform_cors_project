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

  name                = var.app_name
  location            = var.location
  resource_group_name = var.resource_group_name

  os_type  = var.os_type
  sku_name = var.sku_name

  # OS-specific application stacks
  application_stack         = var.os_type == "Linux" ? var.linux_application_stack : null
  windows_application_stack = var.os_type == "Windows" ? var.windows_application_stack : null

  app_settings = var.app_settings

  # Private endpoint (Premium v2/v3 SKU) - the site becomes private-only
  enable_private_endpoint    = var.enable_private_endpoint
  private_endpoint_subnet_id = var.enable_private_endpoint ? azurerm_subnet.private_endpoint.id : null
  virtual_network_id         = var.enable_private_endpoint ? azurerm_virtual_network.this.id : null

  # Microsoft Entra authentication + managed identity
  enable_system_assigned_identity = var.enable_system_assigned_identity

  auth_settings = var.enable_auth ? {
    enabled                    = true
    client_id                  = var.auth_client_id
    client_secret_setting_name = var.auth_client_secret_setting_name
    tenant_auth_endpoint       = "https://login.microsoftonline.com/${var.auth_tenant_id}/v2.0"
    require_authentication     = true
    unauthenticated_action     = var.auth_unauthenticated_action
    token_store_enabled        = false
  } : null

  client_secret = var.auth_client_secret

  cors_allowed_origins = var.cors_allowed_origins

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Virtual network + subnet for the private endpoint
# -----------------------------------------------------------------------------
resource "azurerm_virtual_network" "this" {
  name                = "${var.app_name}-vnet"
  location            = var.location
  resource_group_name = module.webapp_cors.resource_group_name
  address_space       = var.virtual_network_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "private_endpoint" {
  name                                      = "snet-private-endpoint"
  resource_group_name                       = module.webapp_cors.resource_group_name
  virtual_network_name                      = azurerm_virtual_network.this.name
  address_prefixes                          = var.private_endpoint_subnet_prefixes
  private_endpoint_network_policies_enabled = false
}
