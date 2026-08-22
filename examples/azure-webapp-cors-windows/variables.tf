variable "app_name" {
  description = "Name of the Windows web app (must be globally unique within Azure)."
  type        = string
}

variable "location" {
  description = "Azure region in which to create the resources."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group to create."
  type        = string
}

# -----------------------------------------------------------------------------
# High availability
# -----------------------------------------------------------------------------
variable "sku_name" {
  description = "SKU of the App Service plan. Private endpoints and zone redundancy require Premium v2/v3 (e.g. P1v3)."
  type        = string
  default     = "P1v3"
}

variable "zone_redundant" {
  description = "Whether to balance the plan across availability zones (minimum 3 workers)."
  type        = bool
  default     = true
}

variable "worker_count" {
  description = "Number of workers (instances) for the App Service plan."
  type        = number
  default     = 3
}

variable "per_site_scaling_enabled" {
  description = "Whether per-site scaling is enabled on the App Service plan."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Application configuration
# -----------------------------------------------------------------------------
variable "windows_application_stack" {
  description = "Application stack for the Windows web app (see module README)."
  type        = object({
    current_stack                = optional(string, "node")
    docker_image_name            = optional(string)
    docker_registry_url          = optional(string)
    docker_registry_username     = optional(string)
    docker_registry_password     = optional(string)
    dotnet_version               = optional(string)
    dotnet_core_version          = optional(string)
    java_version                 = optional(string)
    java_embedded_server_enabled = optional(bool)
    tomcat_version               = optional(string)
    node_version                 = optional(string, "~20")
    php_version                  = optional(string)
    python                       = optional(bool)
  })
  default = {}
}

variable "app_settings" {
  description = "Application settings (environment variables) for the web app."
  type        = map(string)
  default     = {}
}

variable "connection_strings" {
  description = "Connection strings for the web app (Windows only)."
  type        = map(object({
    type  = string
    value = string
  }))
  default = {}
}

variable "health_check_path" {
  description = "Health check path (e.g. /healthz). Set to null to disable."
  type        = string
  default     = "/healthz"
}

variable "health_check_eviction_time_in_min" {
  description = "Minutes a node can stay unhealthy before eviction (2-10)."
  type        = number
  default     = 2
}

# -----------------------------------------------------------------------------
# Deployment slots
# -----------------------------------------------------------------------------
variable "enable_staging_slot" {
  description = "Whether to create a staging deployment slot."
  type        = bool
  default     = true
}

variable "staging_slot_name" {
  description = "Name of the staging deployment slot."
  type        = string
  default     = "staging"
}

variable "sticky_app_setting_names" {
  description = "App settings that must not be swapped between slots."
  type        = list(string)
  default     = []
}

variable "sticky_connection_string_names" {
  description = "Connection strings that must not be swapped between slots (Windows only)."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Access restrictions
# -----------------------------------------------------------------------------
variable "ip_restrictions" {
  description = "IP access restrictions for the main site (see module README for the rule format)."
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

variable "scm_ip_restrictions" {
  description = "IP access restrictions for the SCM endpoint (see module README for the rule format)."
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
  description = "Whether the SCM endpoint uses the main site restrictions."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------
variable "enable_private_endpoint" {
  description = "Whether to create a private endpoint (site becomes private-only by default)."
  type        = bool
  default     = true
}

variable "virtual_network_address_space" {
  description = "Address space of the virtual network hosting the private endpoint."
  type        = list(string)
  default     = ["10.10.0.0/24"]
}

variable "private_endpoint_subnet_prefixes" {
  description = "Address prefixes of the private endpoint subnet."
  type        = list(string)
  default     = ["10.10.0.0/27"]
}

variable "vnet_integration_subnet_prefixes" {
  description = "Address prefixes of the VNet integration subnet (delegated to Microsoft.Web/serverFarms)."
  type        = list(string)
  default     = ["10.10.0.32/27"]
}

variable "vnet_route_all_enabled" {
  description = "Whether all outbound traffic should go through the VNet."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Identity & authentication
# -----------------------------------------------------------------------------
variable "enable_system_assigned_identity" {
  description = "Whether to assign a system-assigned managed identity to the web app."
  type        = bool
  default     = true
}

variable "create_user_assigned_identity" {
  description = "Whether to create and assign a user-assigned managed identity."
  type        = bool
  default     = true
}

variable "enable_auth" {
  description = "Whether to enable Microsoft Entra ID authentication."
  type        = bool
  default     = false
}

variable "auth_client_id" {
  description = "Client ID of the Entra app registration used for authentication. Required when enable_auth is true."
  type        = string
  default     = null
}

variable "auth_client_secret" {
  description = "Client secret of the Entra app registration. Stored in the app setting named by auth_client_secret_setting_name."
  type        = string
  sensitive   = true
  default     = null
}

variable "auth_client_secret_setting_name" {
  description = "App setting name that holds the Entra client secret."
  type        = string
  default     = "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET"
}

variable "auth_tenant_id" {
  description = "Tenant ID used for the Entra authentication endpoint."
  type        = string
  default     = null
}

variable "auth_unauthenticated_action" {
  description = "Action for unauthenticated requests: RedirectToLoginPage, AllowAnonymous, Return401 or Return403."
  type        = string
  default     = "RedirectToLoginPage"
}

# -----------------------------------------------------------------------------
# Backup
# -----------------------------------------------------------------------------
variable "backup_settings" {
  description = "Backup configuration (see module README). Set to null to disable."
  type        = object({
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
  description = "Custom hostname to bind (CNAME must already exist). Set to null to skip."
  type        = string
  default     = null
}

variable "certificate_pfx_blob" {
  description = "Base64-encoded PFX certificate for the custom domain."
  type        = string
  sensitive   = true
  default     = null
}

variable "certificate_password" {
  description = "Password of the PFX certificate."
  type        = string
  sensitive   = true
  default     = null
}

# -----------------------------------------------------------------------------
# Monitoring & alerts
# -----------------------------------------------------------------------------
variable "enable_monitoring" {
  description = "Whether to enable Application Insights + Log Analytics + diagnostic settings."
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "ID of an existing Log Analytics workspace. When null, the module creates one."
  type        = string
  default     = null
}

variable "enable_alerts" {
  description = "Whether to create metric alerts."
  type        = bool
  default     = true
}

variable "alert_email_addresses" {
  description = "Email addresses that receive metric alerts."
  type        = list(string)
  default     = []
}

variable "alert_settings" {
  description = "Alert thresholds (see module README)."
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

# -----------------------------------------------------------------------------
# CORS & tags
# -----------------------------------------------------------------------------
variable "cors_allowed_origins" {
  description = "Origins allowed to make cross-origin requests to the web app."
  type        = list(string)
  default     = ["https://app.example.com"]
}

variable "cors_support_credentials" {
  description = "Whether CORS requests with credentials are allowed."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Map of tags to apply to the resources."
  type        = map(string)
  default     = {}
}
