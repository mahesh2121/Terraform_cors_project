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

output "identity_principal_id" {
  description = "Principal (object) ID of the system-assigned managed identity. Null when `enable_system_assigned_identity` is false."
  value       = var.enable_system_assigned_identity ? local.web_app.identity[0].principal_id : null
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
