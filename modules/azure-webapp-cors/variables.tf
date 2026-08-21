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

# -----------------------------------------------------------------------------
# App Service plan
# -----------------------------------------------------------------------------
variable "service_plan_name" {
  description = "Name of the App Service plan. Defaults to `<name>-plan` when null."
  type        = string
  default     = null
}

variable "sku_name" {
  description = "SKU of the App Service plan (e.g. F1, B1, S1, P1v2, P1v3). Private endpoints require Premium v2/v3; zone redundancy requires Premium v2/v3 with at least 3 workers."
  type        = string
  default     = "F1"
}

variable "worker_count" {
  description = "Number of workers (instances) allocated to the plan and web app. Raised to 3 when `zone_redundant` is true."
  type        = number
  default     = 1
}

variable "zone_redundant" {
  description = "Whether the App Service plan should balance across availability zones (Premium v2/v3 SKUs, minimum 3 workers)."
  type        = bool
  default     = false
}

variable "per_site_scaling_enabled" {
  description = "Whether per-site scaling is enabled on the App Service plan."
  type        = bool
  default     = false
}

variable "maximum_elastic_worker_count" {
  description = "Maximum number of workers for Elastic/Premium plan auto-scale. Only valid with Elastic (EP) or Premium plans with auto-scaling enabled."
  type        = number
  default     = null
}

# -----------------------------------------------------------------------------
# Site configuration
# -----------------------------------------------------------------------------
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

variable "health_check_path" {
  description = "Path used for the App Service health check (e.g. `/healthz`). Set to null to disable."
  type        = string
  default     = null
}

variable "health_check_eviction_time_in_min" {
  description = "Minutes a node can stay unhealthy before being removed from the load balancer (2-10). Only valid together with `health_check_path`."
  type        = number
  default     = null

  validation {
    condition     = var.health_check_eviction_time_in_min == null || (var.health_check_eviction_time_in_min >= 2 && var.health_check_eviction_time_in_min <= 10)
    error_message = "health_check_eviction_time_in_min must be between 2 and 10 minutes."
  }
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

variable "connection_strings" {
  description = "Connection strings to configure on the web app (Windows only; on Linux use app settings)."
  type        = map(object({
    type  = string
    value = string
  }))
  default = {}
}

variable "sticky_app_setting_names" {
  description = "App setting names that must not be swapped between deployment slots."
  type        = list(string)
  default     = []
}

variable "sticky_connection_string_names" {
  description = "Connection string names that must not be swapped between deployment slots (Windows only)."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Access restrictions
# -----------------------------------------------------------------------------
variable "ip_restrictions" {
  description = <<-EOT
    IP access restrictions for the main site. Each rule supports: `name`,
    `priority` (1-65536, lower wins), `action` (Allow/Deny), and one of
    `ip_address` (CIDR), `service_tag` or `virtual_network_subnet_id`.
  EOT
  type = list(object({
    name                      = string
    priority                  = number
    action                    = optional(string, "Allow")
    ip_address                = optional(string)
    service_tag               = optional(string)
    virtual_network_subnet_id = optional(string)
  }))
  default = []
}

variable "scm_ip_restrictions" {
  description = "IP access restrictions for the SCM (Kudu) endpoint. Same rule format as `ip_restrictions`. The SCM endpoint is already private when a private endpoint is enabled."
  type        = list(object({
    name                      = string
    priority                  = number
    action                    = optional(string, "Allow")
    ip_address                = optional(string)
    service_tag               = optional(string)
    virtual_network_subnet_id = optional(string)
  }))
  default = []
}

variable "scm_use_main_ip_restriction" {
  description = "Whether the SCM endpoint should use the same restrictions as the main site."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# VNet integration (outbound traffic)
# -----------------------------------------------------------------------------
variable "vnet_integration_subnet_id" {
  description = "ID of a subnet delegated to Microsoft.Web/serverFarms for regional VNet integration (outbound traffic). Set to null to disable."
  type        = string
  default     = null
}

variable "vnet_route_all_enabled" {
  description = "Whether all outbound traffic should go through the VNet (NAT/NSG/UDR applied)."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# CORS
# -----------------------------------------------------------------------------
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

variable "user_assigned_identity_ids" {
  description = "IDs of existing user-assigned managed identities to assign to the web app."
  type        = list(string)
  default     = []
}

variable "create_user_assigned_identity" {
  description = "Whether to create a user-assigned managed identity (e.g. for Azure Container Registry pulls or Key Vault references) and assign it to the web app."
  type        = bool
  default     = false
}

variable "user_assigned_identity_name" {
  description = "Name of the user-assigned identity created when `create_user_assigned_identity` is true. Defaults to `<name>-uai`."
  type        = string
  default     = null
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

# -----------------------------------------------------------------------------
# Deployment slot
# -----------------------------------------------------------------------------
variable "enable_staging_slot" {
  description = "Whether to create a staging deployment slot for zero-downtime deployments."
  type        = bool
  default     = false
}

variable "staging_slot_name" {
  description = "Name of the staging deployment slot."
  type        = string
  default     = "staging"
}

# -----------------------------------------------------------------------------
# Backup (Windows and Linux, Standard SKU or higher)
# -----------------------------------------------------------------------------
variable "backup_settings" {
  description = <<-EOT
    Backup configuration (requires Standard SKU or higher and a storage
    account SAS URL). Set to null to disable backups. The `storage_account_url`
    must be a SAS URL pointing to the backup container.
  EOT
  type = object({
    storage_account_url      = string
    frequency_interval       = optional(number, 1)
    frequency_unit           = optional(string, "Day")
    retention_period_days    = optional(number, 30)
    keep_at_least_one_backup = optional(bool, true)
    start_time               = optional(string)
  })
  default = null
}

# -----------------------------------------------------------------------------
# Custom domain + TLS certificate
# -----------------------------------------------------------------------------
variable "custom_domain" {
  description = "Custom hostname to bind to the web app (e.g. `www.example.com`). The CNAME/verification record must already exist in DNS. Set to null to skip."
  type        = string
  default     = null
}

variable "certificate_pfx_blob" {
  description = "Base64-encoded PFX certificate for the custom domain (SNI binding). Set together with `custom_domain`."
  type        = string
  sensitive   = true
  default     = null
}

variable "certificate_password" {
  description = "Password of the PFX certificate passed in `certificate_pfx_blob`."
  type        = string
  sensitive   = true
  default     = null
}

# -----------------------------------------------------------------------------
# Monitoring: Application Insights, Log Analytics, diagnostics, alerts
# -----------------------------------------------------------------------------
variable "enable_monitoring" {
  description = "Whether to create Application Insights (workspace-based), a Log Analytics workspace (unless one is provided) and diagnostic settings for the web app."
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "ID of an existing Log Analytics workspace. When null and monitoring is enabled, the module creates one."
  type        = string
  default     = null
}

variable "log_analytics_workspace_sku" {
  description = "SKU of the Log Analytics workspace created by the module."
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_retention_in_days" {
  description = "Retention in days of the Log Analytics workspace created by the module (30-730)."
  type        = number
  default     = 30
}

variable "application_insights_type" {
  description = "Application type of the Application Insights instance."
  type        = string
  default     = "web"
}

variable "enable_alerts" {
  description = "Whether to create metric alert rules for the web app. Requires `alert_email_addresses` (an action group is created from them)."
  type        = bool
  default     = false
}

variable "alert_email_addresses" {
  description = "Email addresses that receive metric alerts (added to a module-managed action group)."
  type        = list(string)
  default     = []
}

variable "alert_settings" {
  description = "Thresholds for the metric alert rules (created when `enable_alerts` is true and `alert_email_addresses` is not empty)."
  type        = object({
    http_5xx_enabled           = optional(bool, true)
    http_5xx_threshold         = optional(number, 10)
    http_4xx_enabled           = optional(bool, false)
    http_4xx_threshold         = optional(number, 50)
    response_time_enabled      = optional(bool, false)
    response_time_threshold_ms = optional(number, 1000)
    cpu_enabled                = optional(bool, false)
    cpu_threshold              = optional(number, 80)
  })
  default = {}
}

variable "tags" {
  description = "Map of tags to apply to all supported resources."
  type        = map(string)
  default     = {}
}
