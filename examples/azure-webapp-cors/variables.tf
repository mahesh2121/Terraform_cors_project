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

variable "sku_name" {
  description = "SKU of the App Service plan."
  type        = string
  default     = "F1"
}

variable "application_stack" {
  description = "Language stack configuration (see module README)."
  type        = map(string)
  default     = {
    node_version = "20-lts"
  }
}

variable "app_settings" {
  description = "Application settings (environment variables) for the web app."
  type        = map(string)
  default     = {
    WEBSITE_NODE_DEFAULT_VERSION = "20-lts"
  }
}

variable "cors_allowed_origins" {
  description = "Origins allowed to make cross-origin requests to the web app."
  type        = list(string)
  default     = ["*"]
}

variable "tags" {
  description = "Map of tags to apply to the resources."
  type        = map(string)
  default     = {}
}
