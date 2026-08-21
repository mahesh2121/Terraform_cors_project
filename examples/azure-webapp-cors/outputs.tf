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
