variable "name" {
  description = "Name of the Linux web app. Must be globally unique within Azure."
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

variable "service_plan_name" {
  description = "Name of the App Service plan. Defaults to `<name>-plan` when null."
  type        = string
  default     = null
}

variable "sku_name" {
  description = "SKU of the App Service plan (e.g. F1, B1, S1, P1v2)."
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

variable "app_command_line" {
  description = "Custom startup command for the web app. Set to null to use the default."
  type        = string
  default     = null
}

variable "application_stack" {
  description = <<-EOT
    Language stack configuration. Exactly one of the optional fields should be
    set (e.g. `node_version = "20-lts"`). Docker stacks use `docker_image` and
    `docker_image_tag`. Set to null to use the Azure portal default.
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

variable "tags" {
  description = "Map of tags to apply to all supported resources."
  type        = map(string)
  default     = {}
}
