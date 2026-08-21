variable "app_name" {
  description = "Name of the web app (must be globally unique within Azure)."
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

variable "os_type" {
  description = "Operating system of the web app: Linux or Windows."
  type        = string
  default     = "Windows"
}

variable "sku_name" {
  description = "SKU of the App Service plan. Private endpoints require Premium v2/v3 (e.g. P1v3)."
  type        = string
  default     = "P1v3"
}

variable "linux_application_stack" {
  description = "Language stack for Linux web apps (see module README). Used when os_type is Linux."
  type        = object({
    node_version     = optional(string)
    python_version   = optional(string)
    dotnet_version   = optional(string)
    java_version     = optional(string)
    php_version      = optional(string)
    ruby_version     = optional(string)
    docker_image     = optional(string)
    docker_image_tag = optional(string)
  })
  default = {}
}

variable "windows_application_stack" {
  description = "Application stack for Windows web apps (see module README). Used when os_type is Windows."
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

variable "cors_allowed_origins" {
  description = "Origins allowed to make cross-origin requests to the web app."
  type        = list(string)
  default     = ["*"]
}

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

variable "enable_system_assigned_identity" {
  description = "Whether to assign a system-assigned managed identity to the web app."
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

variable "tags" {
  description = "Map of tags to apply to the resources."
  type        = map(string)
  default     = {}
}
