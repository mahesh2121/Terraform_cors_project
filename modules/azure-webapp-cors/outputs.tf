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
  description = "ID of the Linux web app."
  value       = azurerm_linux_web_app.this.id
}

output "web_app_name" {
  description = "Name of the Linux web app."
  value       = azurerm_linux_web_app.this.name
}

output "default_hostname" {
  description = "Default hostname of the web app, e.g. `<name>.azurewebsites.net`."
  value       = azurerm_linux_web_app.this.default_hostname
}

output "web_app_url" {
  description = "HTTPS URL of the web app."
  value       = "https://${azurerm_linux_web_app.this.default_hostname}"
}

output "outbound_ip_addresses" {
  description = "List of outbound IP addresses of the web app."
  value       = split(",", azurerm_linux_web_app.this.outbound_ip_addresses)
}

output "cors_configuration_id" {
  description = "ID of the CORS configuration managed via azapi."
  value       = azapi_update_resource.cors.id
}
