# -----------------------------------------------------------------------------
# Resource group (create or reference)
# -----------------------------------------------------------------------------
data "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 0 : 1

  name = var.resource_group_name
}

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

locals {
  resource_group_name     = var.create_resource_group ? azurerm_resource_group.this[0].name : data.azurerm_resource_group.this[0].name
  resource_group_location = var.create_resource_group ? azurerm_resource_group.this[0].location : data.azurerm_resource_group.this[0].location
  service_plan_name       = var.service_plan_name != null ? var.service_plan_name : "${var.name}-plan"

  # Site is private-only by default when a private endpoint is enabled.
  public_network_access_enabled = var.public_network_access_enabled != null ? var.public_network_access_enabled : !var.enable_private_endpoint

  # Inject the Entra client secret into app settings (named by auth_settings).
  auth_app_settings = var.client_secret != null && var.auth_settings != null ? { (var.auth_settings.client_secret_setting_name) = var.client_secret } : {}
  app_settings      = merge(var.app_settings, local.auth_app_settings)
}

# -----------------------------------------------------------------------------
# App Service plan
# -----------------------------------------------------------------------------
resource "azurerm_service_plan" "this" {
  name                = local.service_plan_name
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  os_type             = var.os_type
  sku_name            = var.sku_name
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# Linux web app
# -----------------------------------------------------------------------------
resource "azurerm_linux_web_app" "this" {
  count = var.os_type == "Linux" ? 1 : 0

  name                          = var.name
  resource_group_name           = local.resource_group_name
  location                      = local.resource_group_location
  service_plan_id               = azurerm_service_plan.this.id
  https_only                    = var.https_only
  public_network_access_enabled = local.public_network_access_enabled
  app_settings                  = local.app_settings
  tags                          = var.tags

  site_config {
    always_on           = var.always_on
    app_command_line    = var.app_command_line
    ftps_state          = var.ftps_state
    http2_enabled       = var.http2_enabled
    minimum_tls_version = var.minimum_tls_version

    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []

      content {
        node_version     = try(application_stack.value.node_version, null)
        python_version   = try(application_stack.value.python_version, null)
        dotnet_version   = try(application_stack.value.dotnet_version, null)
        java_version     = try(application_stack.value.java_version, null)
        php_version      = try(application_stack.value.php_version, null)
        ruby_version     = try(application_stack.value.ruby_version, null)
        docker_image     = try(application_stack.value.docker_image, null)
        docker_image_tag = try(application_stack.value.docker_image_tag, null)
      }
    }
  }

  dynamic "identity" {
    for_each = var.enable_system_assigned_identity ? [1] : []

    content {
      type = "SystemAssigned"
    }
  }

  dynamic "auth_settings_v2" {
    for_each = var.auth_settings != null ? [var.auth_settings] : []

    content {
      auth_enabled           = auth_settings.value.enabled
      require_authentication = auth_settings.value.require_authentication
      unauthenticated_action = auth_settings.value.unauthenticated_action
      default_provider       = "azureactivedirectory"

      active_directory_v2 {
        client_id                  = auth_settings.value.client_id
        client_secret_setting_name = auth_settings.value.client_secret_setting_name
        tenant_auth_endpoint       = auth_settings.value.tenant_auth_endpoint
      }

      login {
        token_store_enabled = auth_settings.value.token_store_enabled
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Windows web app
# -----------------------------------------------------------------------------
resource "azurerm_windows_web_app" "this" {
  count = var.os_type == "Windows" ? 1 : 0

  name                          = var.name
  resource_group_name           = local.resource_group_name
  location                      = local.resource_group_location
  service_plan_id               = azurerm_service_plan.this.id
  https_only                    = var.https_only
  public_network_access_enabled = local.public_network_access_enabled
  app_settings                  = local.app_settings
  tags                          = var.tags

  site_config {
    always_on           = var.always_on
    app_command_line    = var.app_command_line
    ftps_state          = var.ftps_state
    http2_enabled       = var.http2_enabled
    minimum_tls_version = var.minimum_tls_version

    dynamic "application_stack" {
      for_each = var.windows_application_stack != null ? [var.windows_application_stack] : []

      content {
        current_stack                = application_stack.value.current_stack
        docker_image_name            = application_stack.value.docker_image_name
        docker_registry_url          = application_stack.value.docker_registry_url
        docker_registry_username     = application_stack.value.docker_registry_username
        docker_registry_password     = application_stack.value.docker_registry_password
        dotnet_version               = application_stack.value.dotnet_version
        dotnet_core_version          = application_stack.value.dotnet_core_version
        java_version                 = application_stack.value.java_version
        java_embedded_server_enabled = application_stack.value.java_embedded_server_enabled
        tomcat_version               = application_stack.value.tomcat_version
        node_version                 = application_stack.value.node_version
        php_version                  = application_stack.value.php_version
        python                       = application_stack.value.python
      }
    }
  }

  dynamic "identity" {
    for_each = var.enable_system_assigned_identity ? [1] : []

    content {
      type = "SystemAssigned"
    }
  }

  dynamic "auth_settings_v2" {
    for_each = var.auth_settings != null ? [var.auth_settings] : []

    content {
      auth_enabled           = auth_settings.value.enabled
      require_authentication = auth_settings.value.require_authentication
      unauthenticated_action = auth_settings.value.unauthenticated_action
      default_provider       = "azureactivedirectory"

      active_directory_v2 {
        client_id                  = auth_settings.value.client_id
        client_secret_setting_name = auth_settings.value.client_secret_setting_name
        tenant_auth_endpoint       = auth_settings.value.tenant_auth_endpoint
      }

      login {
        token_store_enabled = auth_settings.value.token_store_enabled
      }
    }
  }
}

locals {
  # Exactly one of the two web apps exists (count is driven by os_type).
  web_app = var.os_type == "Linux" ? azurerm_linux_web_app.this[0] : azurerm_windows_web_app.this[0]
}

# -----------------------------------------------------------------------------
# CORS configuration
#
# azurerm has no dedicated App Service CORS resource, so the platform CORS
# settings are managed through the azapi provider against the `web` config of
# the site: Microsoft.Web/sites/config (properties.cors.allowedOrigins /
# supportCredentials).
# -----------------------------------------------------------------------------
resource "azapi_update_resource" "cors" {
  type      = "Microsoft.Web/sites/config@2022-09-01"
  name      = "web"
  parent_id = local.web_app.id

  body = jsonencode({
    properties = {
      cors = {
        allowedOrigins     = var.cors_allowed_origins
        supportCredentials = var.cors_support_credentials
      }
    }
  })
}

# -----------------------------------------------------------------------------
# Private endpoint + private DNS zone (optional)
# -----------------------------------------------------------------------------
resource "azurerm_private_endpoint" "this" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.name}-pe"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-pe-connection"
    is_manual_connection           = false
    private_connection_resource_id = local.web_app.id
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [local.private_dns_zone_id]
  }
}

resource "azurerm_private_dns_zone" "this" {
  count = var.enable_private_endpoint && var.private_dns_zone_id == null ? 1 : 0

  name                = "privatelink.azurewebsites.net"
  resource_group_name = local.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  count = var.enable_private_endpoint && var.virtual_network_id != null ? 1 : 0

  name                  = "link-${var.name}"
  resource_group_name   = local.resource_group_name
  private_dns_zone_name = "privatelink.azurewebsites.net"
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = true
  tags                  = var.tags
}

locals {
  private_dns_zone_id = var.private_dns_zone_id != null ? var.private_dns_zone_id : (var.enable_private_endpoint ? azurerm_private_dns_zone.this[0].id : null)
}
