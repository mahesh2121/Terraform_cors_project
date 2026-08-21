# Azure Web App with CORS module

Standardized Terraform module that provisions a full-featured Azure App
Service web app — **Linux or Windows** — with:

- App Service plan + web app (`azurerm_linux_web_app` / `azurerm_windows_web_app`)
- **CORS** allowed origins + credential support via `azapi` (no native
  `azurerm` resource for App Service CORS)
- **Private endpoint** (Premium v2/v3 SKUs) with private DNS zone
  (`privatelink.azurewebsites.net`) and VNet link, private-only access by default
- **Microsoft Entra ID authentication** (`auth_settings_v2`) with client
  secret injected into app settings
- **System-assigned managed identity**
- Configurable language stacks (Linux: Node/Python/.NET/Java/PHP/Ruby/Docker;
  Windows: dotnet/dotnetcore/node/python/php/java/Docker)
- HTTPS-only, HTTP/2, minimum TLS version, FTPS-only defaults

## Usage

### Linux web app with CORS

```hcl
module "webapp_cors" {
  source = "github.com/mahesh2121/Terraform_cors_project//modules/azure-webapp-cors?ref=modules/azure-webapp-cors/v1.1.0"

  name                = "my-cors-webapp"
  location            = "eastus"
  resource_group_name = "rg-my-cors-webapp"

  cors_allowed_origins = ["https://my-frontend.example.com"]
}
```

### Windows web app with private endpoint, Entra auth and managed identity

```hcl
module "webapp_cors" {
  source = "github.com/mahesh2121/Terraform_cors_project//modules/azure-webapp-cors?ref=modules/azure-webapp-cors/v1.1.0"

  name                = "my-private-webapp"
  location            = "eastus"
  resource_group_name = "rg-my-private-webapp"

  os_type  = "Windows"
  sku_name = "P1v3" # private endpoints require Premium v2/v3

  windows_application_stack = {
    current_stack = "node"
    node_version  = "~20"
  }

  enable_private_endpoint   = true
  private_endpoint_subnet_id = azurerm_subnet.pe.id
  virtual_network_id        = azurerm_virtual_network.this.id

  enable_system_assigned_identity = true

  auth_settings = {
    enabled                    = true
    client_id                  = "00000000-0000-0000-0000-000000000000"
    client_secret_setting_name = "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET"
    tenant_auth_endpoint       = "https://login.microsoftonline.com/<tenant-id>/v2.0"
  }
  client_secret = var.auth_client_secret # injected into app settings
}
```

> **Notes:**
> - When `enable_private_endpoint` is true, `public_network_access_enabled`
>   defaults to `false` (private-only). Set it to `true` explicitly if you
>   want public access alongside the private endpoint.
> - The caller must configure the `azurerm` provider (including the required
>   `features {}` block) and authenticate (e.g. via `ARM_*` environment
>   variables or Azure CLI). See
>   [`examples/azure-webapp-cors`](../../examples/azure-webapp-cors) for a
>   complete, runnable example (Windows + private endpoint + auth + identity).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | >= 1.15, < 3.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.80, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | >= 1.15, < 3.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.80, < 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azapi_update_resource.cors](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/update_resource) | resource |
| [azurerm_linux_web_app.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app) | resource |
| [azurerm_private_dns_zone.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_service_plan.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |
| [azurerm_windows_web_app.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_web_app) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_always_on"></a> [always\_on](#input\_always\_on) | Whether the web app is always on. Note: not supported on the free (F1) tier. | `bool` | `false` | no |
| <a name="input_app_command_line"></a> [app\_command\_line](#input\_app\_command\_line) | Custom startup command for the web app. Set to null to use the default. | `string` | `null` | no |
| <a name="input_app_settings"></a> [app\_settings](#input\_app\_settings) | Application settings (environment variables) for the web app. | `map(string)` | `{}` | no |
| <a name="input_application_stack"></a> [application\_stack](#input\_application\_stack) | Language stack configuration for Linux web apps. Exactly one of the optional fields should be set (e.g. `node_version = "20-lts"`). Docker stacks use `docker_image` and `docker_image_tag`. Set to null to use the Azure portal default. Ignored when `os_type` is Windows. | <pre>object({<br>    node_version     = optional(string)<br>    python_version   = optional(string)<br>    dotnet_version   = optional(string)<br>    java_version     = optional(string)<br>    php_version      = optional(string)<br>    ruby_version     = optional(string)<br>    docker_image     = optional(string)<br>    docker_image_tag = optional(string)<br>  })</pre> | <pre>{<br>  "node_version": "20-lts"<br>}</pre> | no |
| <a name="input_auth_settings"></a> [auth\_settings](#input\_auth\_settings) | Microsoft Entra ID (AAD) authentication settings (auth_settings_v2). Set to null to disable authentication. When enabled, the client secret is read from the app setting named by `client_secret_setting_name`; use the `client_secret` variable to inject it into app settings. | <pre>object({<br>    enabled                    = bool<br>    client_id                  = string<br>    client_secret_setting_name = string<br>    tenant_auth_endpoint       = string<br>    require_authentication     = optional(bool, true)<br>    unauthenticated_action     = optional(string, "RedirectToLoginPage")<br>    token_store_enabled        = optional(bool, false)<br>  })</pre> | `null` | no |
| <a name="input_client_secret"></a> [client\_secret](#input\_client\_secret) | Client secret for Microsoft Entra authentication. Injected into app settings under `auth_settings.client_secret_setting_name`. Marked sensitive. | `string` | `null` | no |
| <a name="input_cors_allowed_origins"></a> [cors\_allowed\_origins](#input\_cors\_allowed\_origins) | List of origins allowed to make cross-origin requests to the web app. Use `["*"]` to allow all origins (not recommended for production). | `list(string)` | <pre>[<br>  "*"<br>]</pre> | no |
| <a name="input_cors_support_credentials"></a> [cors\_support\_credentials](#input\_cors\_support\_credentials) | Whether CORS requests with credentials (cookies, HTTP authentication) are allowed. | `bool` | `false` | no |
| <a name="input_create_resource_group"></a> [create\_resource\_group](#input\_create\_resource\_group) | Whether to create the resource group or use an existing one. | `bool` | `true` | no |
| <a name="input_enable_private_endpoint"></a> [enable\_private\_endpoint](#input\_enable\_private\_endpoint) | Whether to create a private endpoint so the web app is reachable only from a virtual network. Requires a Premium v2/v3 SKU and `private_endpoint_subnet_id`. | `bool` | `false` | no |
| <a name="input_enable_system_assigned_identity"></a> [enable\_system\_assigned\_identity](#input\_enable\_system\_assigned\_identity) | Whether to assign a system-assigned managed identity to the web app. | `bool` | `false` | no |
| <a name="input_ftps_state"></a> [ftps\_state](#input\_ftps\_state) | State of FTPS deployment: AllAllowed, FtpsOnly or Disabled. | `string` | `"FtpsOnly"` | no |
| <a name="input_http2_enabled"></a> [http2\_enabled](#input\_http2\_enabled) | Whether to enable HTTP/2 for the web app. | `bool` | `true` | no |
| <a name="input_https_only"></a> [https\_only](#input\_https\_only) | Whether to redirect all HTTP traffic to HTTPS. | `bool` | `true` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region in which to create the resources. | `string` | n/a | yes |
| <a name="input_minimum_tls_version"></a> [minimum\_tls\_version](#input\_minimum\_tls\_version) | Minimum TLS version for the web app. | `string` | `"1.2"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the web app. Must be globally unique within Azure. | `string` | n/a | yes |
| <a name="input_os_type"></a> [os\_type](#input\_os\_type) | Operating system of the web app: Linux or Windows. | `string` | `"Linux"` | no |
| <a name="input_private_dns_zone_id"></a> [private\_dns\_zone\_id](#input\_private\_dns\_zone\_id) | ID of an existing private DNS zone (`privatelink.azurewebsites.net`). When null, the module creates and manages the zone. | `string` | `null` | no |
| <a name="input_private_endpoint_subnet_id"></a> [private\_endpoint\_subnet\_id](#input\_private\_endpoint\_subnet\_id) | ID of the subnet in which to create the private endpoint. Required when `enable_private_endpoint` is true. | `string` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether public network access is enabled for the web app. Defaults to false when a private endpoint is enabled, true otherwise. | `bool` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group. Created when `create_resource_group` is true, otherwise looked up. | `string` | n/a | yes |
| <a name="input_service_plan_name"></a> [service\_plan\_name](#input\_service\_plan\_name) | Name of the App Service plan. Defaults to `<name>-plan` when null. | `string` | `null` | no |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | SKU of the App Service plan (e.g. F1, B1, S1, P1v2). Private endpoints require the Premium v2/v3 tiers (P1v2, P1v3, ...). | `string` | `"F1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all supported resources. | `map(string)` | `{}` | no |
| <a name="input_virtual_network_id"></a> [virtual\_network\_id](#input\_virtual\_network\_id) | ID of the virtual network to link to the private DNS zone (for name resolution). Required when the module creates the zone. When an existing zone is used, only set this if the zone lives in the web app's resource group (the module creates the VNet link there); otherwise link your VNet to the zone yourself and leave this null. | `string` | `null` | no |
| <a name="input_windows_application_stack"></a> [windows\_application\_stack](#input\_windows\_application\_stack) | Application stack configuration for Windows web apps. `current_stack` should be one of dotnet, dotnetcore, node, python, php or java. Docker containers use `docker_image_name` (+ registry settings). Set to null to use the Azure portal default. Ignored when `os_type` is Linux. | <pre>object({<br>    current_stack                = optional(string)<br>    docker_image_name            = optional(string)<br>    docker_registry_url          = optional(string)<br>    docker_registry_username     = optional(string)<br>    docker_registry_password     = optional(string)<br>    dotnet_version               = optional(string)<br>    dotnet_core_version          = optional(string)<br>    java_version                 = optional(string)<br>    java_embedded_server_enabled = optional(bool)<br>    tomcat_version               = optional(string)<br>    node_version                 = optional(string)<br>    php_version                  = optional(string)<br>    python                       = optional(bool)<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cors_configuration_id"></a> [cors\_configuration\_id](#output\_cors\_configuration\_id) | ID of the CORS configuration managed via azapi. |
| <a name="output_default_hostname"></a> [default\_hostname](#output\_default\_hostname) | Default hostname of the web app, e.g. `<name>.azurewebsites.net`. |
| <a name="output_identity_principal_id"></a> [identity\_principal\_id](#output\_identity\_principal\_id) | Principal (object) ID of the system-assigned managed identity. Null when `enable_system_assigned_identity` is false. |
| <a name="output_location"></a> [location](#output\_location) | Azure region of the deployed resources. |
| <a name="output_outbound_ip_addresses"></a> [outbound\_ip\_addresses](#output\_outbound\_ip\_addresses) | List of outbound IP addresses of the web app. |
| <a name="output_private_dns_zone_id"></a> [private\_dns\_zone\_id](#output\_private\_dns\_zone\_id) | ID of the private DNS zone used for the private endpoint. Null when `enable_private_endpoint` is false. |
| <a name="output_private_endpoint_id"></a> [private\_endpoint\_id](#output\_private\_endpoint\_id) | ID of the private endpoint. Null when `enable_private_endpoint` is false. |
| <a name="output_private_endpoint_private_ip_address"></a> [private\_endpoint\_private\_ip\_address](#output\_private\_endpoint\_private\_ip\_address) | Primary private IP address of the private endpoint. Null when `enable_private_endpoint` is false. (The SCM endpoint receives a second IP registered in the private DNS zone.) |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the resource group hosting the web app. |
| <a name="output_service_plan_id"></a> [service\_plan\_id](#output\_service\_plan\_id) | ID of the App Service plan. |
| <a name="output_service_plan_name"></a> [service\_plan\_name](#output\_service\_plan\_name) | Name of the App Service plan. |
| <a name="output_web_app_id"></a> [web\_app\_id](#output\_web\_app\_id) | ID of the web app. |
| <a name="output_web_app_name"></a> [web\_app\_name](#output\_web\_app\_name) | Name of the web app. |
| <a name="output_web_app_os_type"></a> [web\_app\_os\_type](#output\_web\_app\_os\_type) | Operating system of the web app (Linux or Windows). |
| <a name="output_web_app_url"></a> [web\_app\_url](#output\_web\_app\_url) | HTTPS URL of the web app. |
<!-- END_TF_DOCS -->
