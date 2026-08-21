output "resource_group_name" {
  description = "Name of the resource group hosting the web app."
  value       = local.resource_group_name
}

output "location" {
  description = "Azure region of the deployed resources."
  value       = local.resource_group_location
}

output "service_plan_id" {
  description = "ID of the App Service plan."
  value       = azurerm_service_plan.this.id
}

output "service_plan_name" {
  description = "Name of the App Service plan."
  value       = azurerm_service_plan.this.name
}

output "web_app_id" {
  description = "ID of the web app."
  value       = local.web_app.id
}

output "web_app_name" {
  description = "Name of the web app."
  value       = local.web_app.name
}

output "web_app_os_type" {
  description = "Operating system of the web app (Linux or Windows)."
  value       = var.os_type
}

output "default_hostname" {
  description = "Default hostname of the web app, e.g. `<name>.azurewebsites.net`."
  value       = local.web_app.default_hostname
}

output "web_app_url" {
  description = "HTTPS URL of the web app."
  value       = "https://${local.web_app.default_hostname}"
}

output "outbound_ip_addresses" {
  description = "List of outbound IP addresses of the web app."
  value       = split(",", local.web_app.outbound_ip_addresses)
}

output "identity_type" {
  description = "Managed identity type assigned to the web app (null when no identity is configured)."
  value       = local.identity_type
}

output "identity_principal_id" {
  description = "Principal (object) ID of the system-assigned managed identity. Null when `enable_system_assigned_identity` is false."
  value       = var.enable_system_assigned_identity ? local.web_app.identity[0].principal_id : null
}

output "user_assigned_identity_id" {
  description = "ID of the user-assigned identity created by the module. Null when `create_user_assigned_identity` is false."
  value       = var.create_user_assigned_identity ? azurerm_user_assigned_identity.this[0].id : null
}

output "user_assigned_identity_client_id" {
  description = "Client ID of the user-assigned identity created by the module. Null when `create_user_assigned_identity` is false."
  value       = var.create_user_assigned_identity ? azurerm_user_assigned_identity.this[0].client_id : null
}

output "user_assigned_identity_principal_id" {
  description = "Principal (object) ID of the user-assigned identity created by the module. Null when `create_user_assigned_identity` is false."
  value       = var.create_user_assigned_identity ? azurerm_user_assigned_identity.this[0].principal_id : null
}

output "cors_configuration_id" {
  description = "ID of the CORS configuration managed via azapi."
  value       = azapi_update_resource.cors.id
}

output "private_endpoint_id" {
  description = "ID of the private endpoint. Null when `enable_private_endpoint` is false."
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.this[0].id : null
}

output "private_endpoint_private_ip_address" {
  description = "Primary private IP address of the private endpoint. Null when `enable_private_endpoint` is false. (The SCM endpoint receives a second IP registered in the private DNS zone.)"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.this[0].private_service_connection[0].private_ip_address : null
}

output "private_dns_zone_id" {
  description = "ID of the private DNS zone used for the private endpoint. Null when `enable_private_endpoint` is false."
  value       = local.private_dns_zone_id
}

output "staging_slot_default_hostname" {
  description = "Default hostname of the staging deployment slot. Null when `enable_staging_slot` is false."
  value       = local.staging_slot != null ? local.staging_slot.default_hostname : null
}

output "vnet_integration_connection_id" {
  description = "ID of the regional VNet integration (swift) connection. Null when `vnet_integration_subnet_id` is not set."
  value       = var.vnet_integration_subnet_id != null ? azurerm_app_service_virtual_network_swift_connection.this[0].id : null
}

output "custom_domain_binding_id" {
  description = "ID of the custom hostname binding. Null when `custom_domain` is not set."
  value       = var.custom_domain != null ? azurerm_app_service_custom_hostname_binding.this[0].id : null
}

output "certificate_id" {
  description = "ID of the TLS certificate uploaded for the custom domain. Null when no certificate is provided."
  value       = var.custom_domain != null && var.certificate_pfx_blob != null ? azurerm_app_service_certificate.this[0].id : null
}

output "certificate_thumbprint" {
  description = "Thumbprint of the TLS certificate bound to the custom domain. Null when no certificate is provided."
  value       = var.custom_domain != null && var.certificate_pfx_blob != null ? azurerm_app_service_certificate.this[0].thumbprint : null
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace used for diagnostics. Null when monitoring is disabled."
  value       = local.log_analytics_workspace_id
}

output "application_insights_id" {
  description = "ID of the Application Insights instance. Null when monitoring is disabled."
  value       = var.enable_monitoring ? azurerm_application_insights.this[0].id : null
}

output "application_insights_connection_string" {
  description = "Connection string of the Application Insights instance (also injected into app settings). Null when monitoring is disabled."
  value       = var.enable_monitoring ? azurerm_application_insights.this[0].connection_string : null
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key of the Application Insights instance. Null when monitoring is disabled."
  value       = var.enable_monitoring ? azurerm_application_insights.this[0].instrumentation_key : null
}

output "diagnostic_setting_id" {
  description = "ID of the diagnostic setting sending web app logs and metrics to Log Analytics. Null when monitoring is disabled."
  value       = var.enable_monitoring ? azurerm_monitor_diagnostic_setting.this[0].id : null
}

output "action_group_id" {
  description = "ID of the alert action group created by the module. Null when alerts are disabled or no email addresses are configured."
  value       = var.enable_alerts && length(var.alert_email_addresses) > 0 ? azurerm_monitor_action_group.this[0].id : null
}

output "metric_alert_id" {
  description = "ID of the metric alert rule. Null when alerts are disabled or no criteria are enabled."
  value       = var.enable_alerts && length(var.alert_email_addresses) > 0 && length(local.alert_criteria) > 0 ? azurerm_monitor_metric_alert.this[0].id : null
}
