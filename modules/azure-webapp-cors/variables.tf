variable "name" {
  description = "Name of the web app. Must be globally unique within Azure."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,59}$", var.name))
    error_message = "Web app name must be 1-60 characters long and contain only letters, numbers and hyphens, starting with a letter or number."
  }
}

variable "location" {
  description = "Azure region in which to create the resources."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group. Created when `create_resource_group` is true, otherwise looked up."
  type        = string
}

variable "create_resource_group" {
  description = "Whether to create the resource group or use an existing one."
  type        = bool
  default     = true
}

variable "os_type" {
  description = "Operating system of the web app: Linux or Windows."
  type        = string
  default     = "Linux"

  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "os_type must be one of: Linux, Windows."
  }
}

variable "service_plan_name" {
  description = "Name of the App Service plan. Defaults to `<name>-plan` when null."
  type        = string
  default     = null
}

variable "sku_name" {
  description = "SKU of the App Service plan (e.g. F1, B1, S1, P1v2). Private endpoints require the Premium v2/v3 tiers (P1v2, P1v3, ...)."
  type        = string
  default     = "F1"
}

variable "https_only" {
  description = "Whether to redirect all HTTP traffic to HTTPS."
  type        = bool
  default     = true
}

variable "always_on" {
  description = "Whether the web app is always on. Note: not supported on the free (F1) tier."
  type        = bool
  default     = false
}

variable "http2_enabled" {
  description = "Whether to enable HTTP/2 for the web app."
  type        = bool
  default     = true
}

variable "minimum_tls_version" {
  description = "Minimum TLS version for the web app."
  type        = string
  default     = "1.2"
}

variable "ftps_state" {
  description = "State of FTPS deployment: AllAllowed, FtpsOnly or Disabled."
  type        = string
  default     = "FtpsOnly"

  validation {
    condition     = contains(["AllAllowed", "FtpsOnly", "Disabled"], var.ftps_state)
    error_message = "ftps_state must be one of: AllAllowed, FtpsOnly, Disabled."
  }
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled for the web app. Defaults to false when a private endpoint is enabled, true otherwise."
  type        = bool
  default     = null
}

variable "app_command_line" {
  description = "Custom startup command for the web app. Set to null to use the default."
  type        = string
  default     = null
}

variable "application_stack" {
  description = <<-EOT
    Language stack configuration for Linux web apps. Exactly one of the
    optional fields should be set (e.g. `node_version = "20-lts"`). Docker
    stacks use `docker_image` and `docker_image_tag`. Set to null to use the
    Azure portal default. Ignored when `os_type` is Windows.
  EOT
  type = object({
    node_version     = optional(string)
    python_version   = optional(string)
    dotnet_version   = optional(string)
    java_version     = optional(string)
    php_version      = optional(string)
    ruby_version     = optional(string)
    docker_image     = optional(string)
    docker_image_tag = optional(string)
  })
  default = {
    node_version = "20-lts"
  }
}

variable "windows_application_stack" {
  description = <<-EOT
    Application stack configuration for Windows web apps. `current_stack`
    should be one of dotnet, dotnetcore, node, python, php or java. Docker
    containers use `docker_image_name` (+ registry settings). Set to null to
    use the Azure portal default. Ignored when `os_type` is Linux.
  EOT
  type = object({
    current_stack                = optional(string)
    docker_image_name            = optional(string)
    docker_registry_url          = optional(string)
    docker_registry_username     = optional(string)
    docker_registry_password     = optional(string)
    dotnet_version               = optional(string)
    dotnet_core_version          = optional(string)
    java_version                 = optional(string)
    java_embedded_server_enabled = optional(bool)
    tomcat_version               = optional(string)
    node_version                 = optional(string)
    php_version                  = optional(string)
    python                       = optional(bool)
  })
  default = null
}

variable "app_settings" {
  description = "Application settings (environment variables) for the web app."
  type        = map(string)
  default     = {}
}

variable "cors_allowed_origins" {
  description = "List of origins allowed to make cross-origin requests to the web app. Use `[\"*\"]` to allow all origins (not recommended for production)."
  type        = list(string)
  default     = ["*"]
}

variable "cors_support_credentials" {
  description = "Whether CORS requests with credentials (cookies, HTTP authentication) are allowed."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Authentication & identity
# -----------------------------------------------------------------------------
variable "enable_system_assigned_identity" {
  description = "Whether to assign a system-assigned managed identity to the web app."
  type        = bool
  default     = false
}

variable "auth_settings" {
  description = <<-EOT
    Microsoft Entra ID (AAD) authentication settings (auth_settings_v2). Set
    to null to disable authentication. When enabled, the client secret is read
    from the app setting named by `client_secret_setting_name`; use the
    `client_secret` variable to inject it into app settings.
  EOT
  type = object({
    enabled                    = bool
    client_id                  = string
    client_secret_setting_name = string
    tenant_auth_endpoint       = string
    require_authentication     = optional(bool, true)
    unauthenticated_action     = optional(string, "RedirectToLoginPage")
    token_store_enabled        = optional(bool, false)
  })
  default = null
}

variable "client_secret" {
  description = "Client secret for Microsoft Entra authentication. Injected into app settings under `auth_settings.client_secret_setting_name`. Marked sensitive."
  type        = string
  sensitive   = true
  default     = null
}

# -----------------------------------------------------------------------------
# Private endpoint
# -----------------------------------------------------------------------------
variable "enable_private_endpoint" {
  description = "Whether to create a private endpoint so the web app is reachable only from a virtual network. Requires a Premium v2/v3 SKU and `private_endpoint_subnet_id`."
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "ID of the subnet in which to create the private endpoint. Required when `enable_private_endpoint` is true."
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "ID of an existing private DNS zone (`privatelink.azurewebsites.net`). When null, the module creates and manages the zone."
  type        = string
  default     = null
}

variable "virtual_network_id" {
  description = "ID of the virtual network to link to the private DNS zone (for name resolution). Required when the module creates the zone. When an existing zone is used, only set this if the zone lives in the web app's resource group (the module creates the VNet link there); otherwise link your VNet to the zone yourself and leave this null."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to all supported resources."
  type        = map(string)
  default     = {}
}
