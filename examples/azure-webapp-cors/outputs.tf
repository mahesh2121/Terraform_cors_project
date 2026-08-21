output "web_app_url" {
  description = "HTTPS URL of the web app."
  value       = module.webapp_cors.web_app_url
}

output "default_hostname" {
  description = "Default hostname of the web app."
  value       = module.webapp_cors.default_hostname
}

output "resource_group_name" {
  description = "Name of the resource group hosting the web app."
  value       = module.webapp_cors.resource_group_name
}

output "web_app_os_type" {
  description = "Operating system of the web app."
  value       = module.webapp_cors.web_app_os_type
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity."
  value       = module.webapp_cors.identity_principal_id
}

output "private_endpoint_id" {
  description = "ID of the private endpoint (null when disabled)."
  value       = module.webapp_cors.private_endpoint_id
}

output "private_endpoint_private_ip_address" {
  description = "Primary private IP address of the private endpoint (null when disabled)."
  value       = module.webapp_cors.private_endpoint_private_ip_address
}

output "private_dns_zone_id" {
  description = "ID of the private DNS zone (null when private endpoint is disabled)."
  value       = module.webapp_cors.private_dns_zone_id
}
