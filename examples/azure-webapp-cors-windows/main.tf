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

  # Remote state in an Azure Storage container (partial configuration).
  # Initialize with: terraform init -backend-config=backend.azurerm.hcl
  # See backend.azurerm.hcl.example.
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

# -----------------------------------------------------------------------------
# The module with EVERY production feature enabled for a Windows web app.
# See terraform.tfvars.example for a fully populated configuration.
# -----------------------------------------------------------------------------
module "webapp_cors" {
  source = "../../modules/azure-webapp-cors"

  name                = var.app_name
  location            = var.location
  resource_group_name = var.resource_group_name

  # Windows + high availability (zone-redundant Premium plan)
  os_type                  = "Windows"
  sku_name                 = var.sku_name
  zone_redundant           = var.zone_redundant
  worker_count             = var.worker_count
  per_site_scaling_enabled = var.per_site_scaling_enabled

  windows_application_stack = var.windows_application_stack

  # Configuration
  app_settings       = var.app_settings
  connection_strings = var.connection_strings

  # Health checks
  health_check_path                 = var.health_check_path
  health_check_eviction_time_in_min = var.health_check_eviction_time_in_min

  # Zero-downtime deployments
  enable_staging_slot            = var.enable_staging_slot
  staging_slot_name              = var.staging_slot_name
  sticky_app_setting_names       = var.sticky_app_setting_names
  sticky_connection_string_names = var.sticky_connection_string_names

  # Access restrictions
  ip_restrictions             = var.ip_restrictions
  scm_ip_restrictions         = var.scm_ip_restrictions
  scm_use_main_ip_restriction = var.scm_use_main_ip_restriction

  # Private endpoint (site becomes private-only)
  enable_private_endpoint    = var.enable_private_endpoint
  private_endpoint_subnet_id = var.enable_private_endpoint ? azurerm_subnet.private_endpoint.id : null
  virtual_network_id         = var.enable_private_endpoint ? azurerm_virtual_network.this.id : null

  # Outbound traffic through the VNet (regional VNet integration)
  vnet_integration_subnet_id = azurerm_subnet.vnet_integration.id
  vnet_route_all_enabled     = var.vnet_route_all_enabled

  # Microsoft Entra authentication + managed identities
  enable_system_assigned_identity = var.enable_system_assigned_identity
  create_user_assigned_identity   = var.create_user_assigned_identity

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

  # Backups
  backup_settings = var.backup_settings

  # Custom domain + TLS certificate
  custom_domain        = var.custom_domain
  certificate_pfx_blob = var.certificate_pfx_blob
  certificate_password = var.certificate_password

  # Monitoring & alerts
  enable_monitoring          = var.enable_monitoring
  log_analytics_workspace_id = var.log_analytics_workspace_id
  enable_alerts              = var.enable_alerts
  alert_email_addresses      = var.alert_email_addresses
  alert_settings             = var.alert_settings

  # CORS
  cors_allowed_origins     = var.cors_allowed_origins
  cors_support_credentials = var.cors_support_credentials

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Virtual network + subnets (private endpoint, regional VNet integration)
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

resource "azurerm_subnet" "vnet_integration" {
  name                 = "snet-vnet-integration"
  resource_group_name  = module.webapp_cors.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.vnet_integration_subnet_prefixes

  delegation {
    name = "app-service-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}
