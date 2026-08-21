# Azure Web App with CORS module

Standardized Terraform module that provisions an Azure App Service (Linux web
app) with an App Service plan and configures CORS allowed origins on the
platform CORS settings.

## Features

- App Service plan + Linux web app (`azurerm_linux_web_app`)
- CORS allowed origins + credential support via `azapi` (there is no native
  `azurerm` resource for App Service CORS)
- Optional resource group creation
- Configurable language stack (Node, Python, .NET, Java, PHP, Ruby, Docker)
- HTTPS-only, HTTP/2, minimum TLS version, FTPS-only defaults

## Usage

```hcl
module "webapp_cors" {
  source = "github.com/mahesh2121/Terraform_cors_project//modules/azure-webapp-cors?ref=modules/azure-webapp-cors/v1.0.0"

  name                = "my-cors-webapp"
  location            = "eastus"
  resource_group_name = "rg-my-cors-webapp"
  create_resource_group = true

  application_stack = {
    node_version = "20-lts"
  }

  cors_allowed_origins     = ["https://my-frontend.example.com"]
  cors_support_credentials = false

  tags = { Project = "terraform-cors-project" }
}
```

> **Note:** the caller must configure the `azurerm` provider (including the
> required `features {}` block) and authenticate (e.g. via `ARM_*` environment
> variables or Azure CLI). See
> [`examples/azure-webapp-cors`](../../examples/azure-webapp-cors) for a
> complete, runnable example.

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
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_service_plan.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_always_on"></a> [always\_on](#input\_always\_on) | Whether the web app is always on. Note: not supported on the free (F1) tier. | `bool` | `false` | no |
| <a name="input_app_command_line"></a> [app\_command\_line](#input\_app\_command\_line) | Custom startup command for the web app. Set to null to use the default. | `string` | `null` | no |
| <a name="input_app_settings"></a> [app\_settings](#input\_app\_settings) | Application settings (environment variables) for the web app. | `map(string)` | `{}` | no |
| <a name="input_application_stack"></a> [application\_stack](#input\_application\_stack) | Language stack configuration. Exactly one of the optional fields should be<br>set (e.g. `node_version = "20-lts"`). Docker stacks use `docker_image` and<br>`docker_image_tag`. Set to null to use the Azure portal default. | <pre>object({<br>    node_version     = optional(string)<br>    python_version   = optional(string)<br>    dotnet_version   = optional(string)<br>    java_version     = optional(string)<br>    php_version      = optional(string)<br>    ruby_version     = optional(string)<br>    docker_image     = optional(string)<br>    docker_image_tag = optional(string)<br>  })</pre> | <pre>{<br>  "node_version": "20-lts"<br>}</pre> | no |
| <a name="input_cors_allowed_origins"></a> [cors\_allowed\_origins](#input\_cors\_allowed\_origins) | List of origins allowed to make cross-origin requests to the web app. Use `["*"]` to allow all origins (not recommended for production). | `list(string)` | <pre>[<br>  "*"<br>]</pre> | no |
| <a name="input_cors_support_credentials"></a> [cors\_support\_credentials](#input\_cors\_support\_credentials) | Whether CORS requests with credentials (cookies, HTTP authentication) are allowed. | `bool` | `false` | no |
| <a name="input_create_resource_group"></a> [create\_resource\_group](#input\_create\_resource\_group) | Whether to create the resource group or use an existing one. | `bool` | `true` | no |
| <a name="input_ftps_state"></a> [ftps\_state](#input\_ftps\_state) | State of FTPS deployment: AllAllowed, FtpsOnly or Disabled. | `string` | `"FtpsOnly"` | no |
| <a name="input_http2_enabled"></a> [http2\_enabled](#input\_http2\_enabled) | Whether to enable HTTP/2 for the web app. | `bool` | `true` | no |
| <a name="input_https_only"></a> [https\_only](#input\_https\_only) | Whether to redirect all HTTP traffic to HTTPS. | `bool` | `true` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region in which to create the resources. | `string` | n/a | yes |
| <a name="input_minimum_tls_version"></a> [minimum\_tls\_version](#input\_minimum\_tls\_version) | Minimum TLS version for the web app. | `string` | `"1.2"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Linux web app. Must be globally unique within Azure. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group. Created when `create_resource_group` is true, otherwise looked up. | `string` | n/a | yes |
| <a name="input_service_plan_name"></a> [service\_plan\_name](#input\_service\_plan\_name) | Name of the App Service plan. Defaults to `<name>-plan` when null. | `string` | `null` | no |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | SKU of the App Service plan (e.g. F1, B1, S1, P1v2). | `string` | `"F1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all supported resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cors_configuration_id"></a> [cors\_configuration\_id](#output\_cors\_configuration\_id) | ID of the CORS configuration managed via azapi. |
| <a name="output_default_hostname"></a> [default\_hostname](#output\_default\_hostname) | Default hostname of the web app, e.g. `<name>.azurewebsites.net`. |
| <a name="output_location"></a> [location](#output\_location) | Azure region of the deployed resources. |
| <a name="output_outbound_ip_addresses"></a> [outbound\_ip\_addresses](#output\_outbound\_ip\_addresses) | List of outbound IP addresses of the web app. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the resource group hosting the web app. |
| <a name="output_service_plan_id"></a> [service\_plan\_id](#output\_service\_plan\_id) | ID of the App Service plan. |
| <a name="output_service_plan_name"></a> [service\_plan\_name](#output\_service\_plan\_name) | Name of the App Service plan. |
| <a name="output_web_app_id"></a> [web\_app\_id](#output\_web\_app\_id) | ID of the Linux web app. |
| <a name="output_web_app_name"></a> [web\_app\_name](#output\_web\_app\_name) | Name of the Linux web app. |
| <a name="output_web_app_url"></a> [web\_app\_url](#output\_web\_app\_url) | HTTPS URL of the web app. |
<!-- END_TF_DOCS -->
