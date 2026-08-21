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

# -----------------------------------------------------------------------------
# User-assigned managed identity (optional, e.g. for ACR pulls / Key Vault)
# -----------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "this" {
  count = var.create_user_assigned_identity ? 1 : 0

  name                = var.user_assigned_identity_name != null ? var.user_assigned_identity_name : "${var.name}-uai"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------
locals {
  resource_group_name     = var.create_resource_group ? azurerm_resource_group.this[0].name : data.azurerm_resource_group.this[0].name
  resource_group_location = var.create_resource_group ? azurerm_resource_group.this[0].location : data.azurerm_resource_group.this[0].location
  service_plan_name       = var.service_plan_name != null ? var.service_plan_name : "${var.name}-plan"

  # Site is private-only by default when a private endpoint is enabled.
  public_network_access_enabled = var.public_network_access_enabled != null ? var.public_network_access_enabled : !var.enable_private_endpoint

  # Zone redundancy requires at least 3 workers.
  worker_count = var.zone_redundant ? max(var.worker_count, 3) : var.worker_count

  # All user-assigned identities (provided + created) assigned to the web app.
  user_assigned_identity_ids = concat(
    var.user_assigned_identity_ids,
    var.create_user_assigned_identity ? [azurerm_user_assigned_identity.this[0].id] : []
  )

  identity_type = (
    var.enable_system_assigned_identity && length(local.user_assigned_identity_ids) > 0 ? "SystemAssigned, UserAssigned"
    : var.enable_system_assigned_identity ? "SystemAssigned"
    : length(local.user_assigned_identity_ids) > 0 ? "UserAssigned"
    : null
  )

  # Inject the Entra client secret into app settings (named by auth_settings).
  auth_app_settings = var.client_secret != null && var.auth_settings != null ? { (var.auth_settings.client_secret_setting_name) = var.client_secret } : {}

  # Inject the Application Insights connection string when monitoring is enabled.
  monitoring_app_settings = var.enable_monitoring ? { "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.this[0].connection_string } : {}

  app_settings = merge(var.app_settings, local.auth_app_settings, local.monitoring_app_settings)

  # Metric alert criteria assembled from alert_settings.
  alert_criteria = flatten([
    var.enable_alerts && var.alert_settings.http_5xx_enabled ? [{ name = "Http5xx", aggregation = "Total", threshold = var.alert_settings.http_5xx_threshold }] : [],
    var.enable_alerts && var.alert_settings.http_4xx_enabled ? [{ name = "Http4xx", aggregation = "Total", threshold = var.alert_settings.http_4xx_threshold }] : [],
    var.enable_alerts && var.alert_settings.response_time_enabled ? [{ name = "HttpResponseTime", aggregation = "Average", threshold = var.alert_settings.response_time_threshold_ms / 1000 }] : [],
    var.enable_alerts && var.alert_settings.cpu_enabled ? [{ name = "CpuPercentage", aggregation = "Average", threshold = var.alert_settings.cpu_threshold }] : [],
  ])

  diag_log_categories = [
    "AppServiceHTTPLogs",
    "AppServiceConsoleLogs",
    "AppServiceAppLogs",
    "AppServiceAuditLogs",
    "AppServiceIPSecAuditLogs",
    "AppServicePlatformLogs",
    "AppServiceAntivirusScanAuditLogs",
    "AppServiceFileAuditLogs",
  ]
}

# -----------------------------------------------------------------------------
# App Service plan
# -----------------------------------------------------------------------------
resource "azurerm_service_plan" "this" {
  name                         = local.service_plan_name
  resource_group_name          = local.resource_group_name
  location                     = local.resource_group_location
  os_type                      = var.os_type
  sku_name                     = var.sku_name
  worker_count                 = local.worker_count
  zone_balancing_enabled       = var.zone_redundant
  per_site_scaling_enabled     = var.per_site_scaling_enabled
  maximum_elastic_worker_count = var.maximum_elastic_worker_count
  tags                         = var.tags
}

# -----------------------------------------------------------------------------
# Linux web app
# -----------------------------------------------------------------------------
resource "azurerm_linux_web_app" "this" {
  count = var.os_type == "Linux" ? 1 : 0

  name                            = var.name
  resource_group_name             = local.resource_group_name
  location                        = local.resource_group_location
  service_plan_id                 = azurerm_service_plan.this.id
  https_only                      = var.https_only
  public_network_access_enabled   = local.public_network_access_enabled
  app_settings                    = local.app_settings
  key_vault_reference_identity_id = length(local.user_assigned_identity_ids) > 0 ? local.user_assigned_identity_ids[0] : null
  tags                            = var.tags

  site_config {
    always_on                         = var.always_on
    app_command_line                  = var.app_command_line
    ftps_state                        = var.ftps_state
    http2_enabled                     = var.http2_enabled
    minimum_tls_version               = var.minimum_tls_version
    worker_count                      = local.worker_count
    vnet_route_all_enabled            = var.vnet_route_all_enabled
    health_check_path                 = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_eviction_time_in_min
    scm_use_main_ip_restriction       = var.scm_use_main_ip_restriction

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

    dynamic "ip_restriction" {
      for_each = var.ip_restrictions

      content {
        name                      = ip_restriction.value.name
        priority                  = ip_restriction.value.priority
        action                    = ip_restriction.value.action
        ip_address                = ip_restriction.value.ip_address
        service_tag               = ip_restriction.value.service_tag
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
      }
    }

    dynamic "scm_ip_restriction" {
      for_each = var.scm_ip_restrictions

      content {
        name                      = scm_ip_restriction.value.name
        priority                  = scm_ip_restriction.value.priority
        action                    = scm_ip_restriction.value.action
        ip_address                = scm_ip_restriction.value.ip_address
        service_tag               = scm_ip_restriction.value.service_tag
        virtual_network_subnet_id = scm_ip_restriction.value.virtual_network_subnet_id
      }
    }
  }

  dynamic "identity" {
    for_each = local.identity_type != null ? [1] : []

    content {
      type         = local.identity_type
      identity_ids = length(local.user_assigned_identity_ids) > 0 ? local.user_assigned_identity_ids : null
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

  dynamic "backup" {
    for_each = var.backup_settings != null ? [var.backup_settings] : []

    content {
      name                = "${var.name}-backup"
      enabled             = true
      storage_account_url = backup.value.storage_account_url

      schedule {
        frequency_interval       = backup.value.frequency_interval
        frequency_unit           = backup.value.frequency_unit
        retention_period_days    = backup.value.retention_period_days
        keep_at_least_one_backup = backup.value.keep_at_least_one_backup
        start_time               = backup.value.start_time
      }
    }
  }

  dynamic "sticky_settings" {
    for_each = length(var.sticky_app_setting_names) > 0 ? [1] : []

    content {
      app_setting_names = var.sticky_app_setting_names
    }
  }

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# -----------------------------------------------------------------------------
# Windows web app
# -----------------------------------------------------------------------------
resource "azurerm_windows_web_app" "this" {
  count = var.os_type == "Windows" ? 1 : 0

  name                            = var.name
  resource_group_name             = local.resource_group_name
  location                        = local.resource_group_location
  service_plan_id                 = azurerm_service_plan.this.id
  https_only                      = var.https_only
  public_network_access_enabled   = local.public_network_access_enabled
  app_settings                    = local.app_settings
  key_vault_reference_identity_id = length(local.user_assigned_identity_ids) > 0 ? local.user_assigned_identity_ids[0] : null
  tags                            = var.tags

  site_config {
    always_on                         = var.always_on
    app_command_line                  = var.app_command_line
    ftps_state                        = var.ftps_state
    http2_enabled                     = var.http2_enabled
    minimum_tls_version               = var.minimum_tls_version
    vnet_route_all_enabled            = var.vnet_route_all_enabled
    health_check_path                 = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_eviction_time_in_min
    scm_use_main_ip_restriction       = var.scm_use_main_ip_restriction

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

    dynamic "ip_restriction" {
      for_each = var.ip_restrictions

      content {
        name                      = ip_restriction.value.name
        priority                  = ip_restriction.value.priority
        action                    = ip_restriction.value.action
        ip_address                = ip_restriction.value.ip_address
        service_tag               = ip_restriction.value.service_tag
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
      }
    }

    dynamic "scm_ip_restriction" {
      for_each = var.scm_ip_restrictions

      content {
        name                      = scm_ip_restriction.value.name
        priority                  = scm_ip_restriction.value.priority
        action                    = scm_ip_restriction.value.action
        ip_address                = scm_ip_restriction.value.ip_address
        service_tag               = scm_ip_restriction.value.service_tag
        virtual_network_subnet_id = scm_ip_restriction.value.virtual_network_subnet_id
      }
    }
  }

  dynamic "connection_string" {
    for_each = var.connection_strings

    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  dynamic "identity" {
    for_each = local.identity_type != null ? [1] : []

    content {
      type         = local.identity_type
      identity_ids = length(local.user_assigned_identity_ids) > 0 ? local.user_assigned_identity_ids : null
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

  dynamic "backup" {
    for_each = var.backup_settings != null ? [var.backup_settings] : []

    content {
      name                = "${var.name}-backup"
      enabled             = true
      storage_account_url = backup.value.storage_account_url

      schedule {
        frequency_interval       = backup.value.frequency_interval
        frequency_unit           = backup.value.frequency_unit
        retention_period_days    = backup.value.retention_period_days
        keep_at_least_one_backup = backup.value.keep_at_least_one_backup
        start_time               = backup.value.start_time
      }
    }
  }

  dynamic "sticky_settings" {
    for_each = length(var.sticky_app_setting_names) > 0 || length(var.sticky_connection_string_names) > 0 ? [1] : []

    content {
      app_setting_names       = var.sticky_app_setting_names
      connection_string_names = var.sticky_connection_string_names
    }
  }

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
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
# Deployment slot (optional staging environment)
# -----------------------------------------------------------------------------
resource "azurerm_linux_web_app_slot" "this" {
  count = var.enable_staging_slot && var.os_type == "Linux" ? 1 : 0

  name           = var.staging_slot_name
  app_service_id = local.web_app.id
  app_settings   = local.app_settings
  tags           = var.tags

  site_config {
    always_on                         = var.always_on
    ftps_state                        = var.ftps_state
    http2_enabled                     = var.http2_enabled
    minimum_tls_version               = var.minimum_tls_version
    public_network_access_enabled     = local.public_network_access_enabled
    vnet_route_all_enabled            = var.vnet_route_all_enabled
    health_check_path                 = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_eviction_time_in_min

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

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

resource "azurerm_windows_web_app_slot" "this" {
  count = var.enable_staging_slot && var.os_type == "Windows" ? 1 : 0

  name           = var.staging_slot_name
  app_service_id = local.web_app.id
  app_settings   = local.app_settings
  tags           = var.tags

  site_config {
    always_on                         = var.always_on
    ftps_state                        = var.ftps_state
    http2_enabled                     = var.http2_enabled
    minimum_tls_version               = var.minimum_tls_version
    vnet_route_all_enabled            = var.vnet_route_all_enabled
    health_check_path                 = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_eviction_time_in_min

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

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

locals {
  staging_slot = var.os_type == "Linux" ? (
    var.enable_staging_slot ? azurerm_linux_web_app_slot.this[0] : null
  ) : (
    var.enable_staging_slot ? azurerm_windows_web_app_slot.this[0] : null
  )
}

# -----------------------------------------------------------------------------
# Regional VNet integration (outbound traffic)
# -----------------------------------------------------------------------------
resource "azurerm_app_service_virtual_network_swift_connection" "this" {
  count = var.vnet_integration_subnet_id != null ? 1 : 0

  app_service_id = local.web_app.id
  subnet_id      = var.vnet_integration_subnet_id
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

# -----------------------------------------------------------------------------
# Custom domain + TLS certificate binding (optional)
# -----------------------------------------------------------------------------
resource "azurerm_app_service_custom_hostname_binding" "this" {
  count = var.custom_domain != null ? 1 : 0

  hostname            = var.custom_domain
  app_service_name    = local.web_app.name
  resource_group_name = local.resource_group_name
  ssl_state           = var.certificate_pfx_blob != null ? "SniEnabled" : null
  thumbprint          = var.certificate_pfx_blob != null ? azurerm_app_service_certificate.this[0].thumbprint : null
}

resource "azurerm_app_service_certificate" "this" {
  count = var.custom_domain != null && var.certificate_pfx_blob != null ? 1 : 0

  name                = replace(var.custom_domain, ".", "-")
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  pfx_blob            = var.certificate_pfx_blob
  password            = var.certificate_password
  tags                = var.tags
}

resource "azurerm_app_service_certificate_binding" "this" {
  count = var.custom_domain != null && var.certificate_pfx_blob != null ? 1 : 0

  hostname_binding_id = azurerm_app_service_custom_hostname_binding.this[0].id
  certificate_id      = azurerm_app_service_certificate.this[0].id
  ssl_state           = "SniEnabled"
}

# -----------------------------------------------------------------------------
# Monitoring: Log Analytics workspace + Application Insights + diagnostics
# -----------------------------------------------------------------------------
resource "azurerm_log_analytics_workspace" "this" {
  count = var.enable_monitoring && var.log_analytics_workspace_id == null ? 1 : 0

  name                = "${var.name}-la"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  sku                 = var.log_analytics_workspace_sku
  retention_in_days   = var.log_analytics_retention_in_days
  tags                = var.tags
}

locals {
  log_analytics_workspace_id = var.log_analytics_workspace_id != null ? var.log_analytics_workspace_id : (var.enable_monitoring ? azurerm_log_analytics_workspace.this[0].id : null)
}

resource "azurerm_application_insights" "this" {
  count = var.enable_monitoring ? 1 : 0

  name                = "${var.name}-ai"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  application_type    = var.application_insights_type
  workspace_id        = local.log_analytics_workspace_id
  tags                = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.enable_monitoring ? 1 : 0

  name                       = "${var.name}-diagnostics"
  target_resource_id         = local.web_app.id
  log_analytics_workspace_id = local.log_analytics_workspace_id

  dynamic "log" {
    for_each = local.diag_log_categories

    content {
      category = log.value
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# -----------------------------------------------------------------------------
# Metric alerts (optional)
# -----------------------------------------------------------------------------
resource "azurerm_monitor_action_group" "this" {
  count = var.enable_alerts && length(var.alert_email_addresses) > 0 ? 1 : 0

  name                = "${var.name}-ag"
  resource_group_name = local.resource_group_name
  short_name          = substr(replace(var.name, "-", ""), 0, 12)
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.alert_email_addresses

    content {
      name                    = "email-${email_receiver.key}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }
}

resource "azurerm_monitor_metric_alert" "this" {
  count = var.enable_alerts && length(var.alert_email_addresses) > 0 && length(local.alert_criteria) > 0 ? 1 : 0

  name                = "${var.name}-metric-alert"
  resource_group_name = local.resource_group_name
  scopes              = [local.web_app.id]
  frequency           = "PT1M"
  window_size         = "PT5M"
  severity            = 2
  enabled             = true
  auto_mitigate       = true
  tags                = var.tags

  dynamic "criteria" {
    for_each = local.alert_criteria

    content {
      metric_namespace = "Microsoft.Web/sites"
      metric_name      = criteria.value.name
      aggregation      = criteria.value.aggregation
      operator         = "GreaterThan"
      threshold        = criteria.value.threshold
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.this[0].id
  }
}
