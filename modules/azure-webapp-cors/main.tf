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
}

# -----------------------------------------------------------------------------
# App Service plan + Linux web app
# -----------------------------------------------------------------------------
resource "azurerm_service_plan" "this" {
  name                = local.service_plan_name
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = var.name
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = var.https_only
  tags                = var.tags

  app_settings = var.app_settings

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
  parent_id = azurerm_linux_web_app.this.id

  body = jsonencode({
    properties = {
      cors = {
        allowedOrigins     = var.cors_allowed_origins
        supportCredentials = var.cors_support_credentials
      }
    }
  })
}
