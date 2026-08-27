# Azure Web App with CORS module

Standardized, **production-ready** Terraform module that provisions a
full-featured Azure App Service web app — **Linux or Windows** — with:

| Capability | Details |
| ---------- | ------- |
| **CORS** | Allowed origins + credential support via `azapi` (no native `azurerm` resource for App Service CORS) |
| **Private endpoint** | Premium v2/v3 SKUs, private DNS zone (`privatelink.azurewebsites.net`) + VNet link, private-only access by default |
| **Authentication** | Microsoft Entra ID `auth_settings_v2` with client secret injected into app settings |
| **Managed identity** | System-assigned and/or user-assigned (module can create one), `key_vault_reference_identity_id` wiring |
| **Monitoring** | Workspace-based Application Insights, Log Analytics (create or bring your own), diagnostic settings, metric alerts (Http5xx/4xx, response time, CPU) with an email action group |
| **High availability** | Zone redundancy, worker scaling, per-site scaling, elastic worker count |
| **Networking** | IP access restrictions (site + SCM), regional VNet integration for outbound traffic, `vnet_route_all_enabled` |
| **Deployment** | Staging deployment slot, sticky (slot-pinned) settings, `WEBSITE_RUN_FROM_PACKAGE` drift protection |
| **Data protection** | Web app backups with schedule (Windows + Linux, Standard SKU or higher) |
| **Custom domain** | Hostname binding + PFX certificate upload with SNI TLS binding |
| **Security defaults** | HTTPS-only, HTTP/2, minimum TLS 1.2, FTPS-only |
| **Platform** | Linux & Windows language stacks, connection strings (Windows), health checks |

## Usage

### Minimal (Linux, CORS only)

```hcl
module "webapp_cors" {
  source = "github.com/mahesh2121/Terraform_cors_project//modules/azure-webapp-cors?ref=modules/azure-webapp-cors/v1.2.0"

  name                = "my-cors-webapp"
  location            = "eastus"
  resource_group_name = "rg-my-cors-webapp"

  cors_allowed_origins = ["https://my-frontend.example.com"]
}
```

### Production (Windows, private, monitored, authenticated)

```hcl
module "webapp_cors" {
  source = "github.com/mahesh2121/Terraform_cors_project//modules/azure-webapp-cors?ref=modules/azure-webapp-cors/v1.2.0"

  name                = "my-prod-webapp"
  location            = "eastus"
  resource_group_name = "rg-my-prod-webapp"

  os_type  = "Windows"
  sku_name = "P1v3"

  # High availability: 3 workers across availability zones
  zone_redundant = true
  worker_count   = 3

  windows_application_stack = {
    current_stack = "dotnet"
    dotnet_version = "v8.0"
  }

  # Health check
  health_check_path                 = "/healthz"
  health_check_eviction_time_in_min = 2

  # Private-only networking
  enable_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.pe.id
  virtual_network_id         = azurerm_virtual_network.this.id

  # Outbound traffic through the VNet
  vnet_integration_subnet_id = azurerm_subnet.vnet_integration.id
  vnet_route_all_enabled     = true

  # Zero-downtime deployments
  enable_staging_slot = true
  sticky_app_setting_names = ["DATABASE_URL"]

  # Identity + Key Vault references
  enable_system_assigned_identity = true
  create_user_assigned_identity   = true

  # Microsoft Entra authentication
  auth_settings = {
    enabled                    = true
    client_id                  = "00000000-0000-0000-0000-000000000000"
    client_secret_setting_name = "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET"
    tenant_auth_endpoint       = "https://login.microsoftonline.com/<tenant-id>/v2.0"
  }
  client_secret = var.auth_client_secret

  # Backup (Standard SKU or higher)
  backup_settings = {
    storage_account_url    = "https://mystorage.blob.core.windows.net/backups?<SAS>"
    frequency_interval     = 1
    frequency_unit         = "Day"
    retention_period_days  = 30
    keep_at_least_one_backup = true
  }

  # Alerts to the on-call mailbox
  enable_alerts         = true
  alert_email_addresses = ["oncall@example.com"]

  cors_allowed_origins = ["https://app.example.com"]
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
>   complete, runnable example.
> - App Service backups require the Standard SKU or higher and a SAS URL to a
>   storage container. Linux apps must not use the `/home` mount exclusions of
>   the underlying platform (see Azure docs).
> - Auto-heal rules are not modeled by this module (use the portal or Azure
>   Policy); health checks + metric alerts cover the observability path.

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
| [azurerm_application_insights.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |
| [azurerm_app_service_certificate.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_certificate) | resource |
| [azurerm_app_service_certificate_binding.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_certificate_binding) | resource |
| [azurerm_app_service_custom_hostname_binding.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_custom_hostname_binding) | resource |
| [azurerm_app_service_virtual_network_swift_connection.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_virtual_network_swift_connection) | resource |
| [azurerm_linux_web_app.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app) | resource |
| [azurerm_linux_web_app_slot.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app_slot) | resource |
| [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_monitor_action_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group) | resource |
| [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_metric_alert.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_private_dns_zone.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_service_plan.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |
| [azurerm_user_assigned_identity.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_windows_web_app.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_web_app) | resource |
| [azurerm_windows_web_app_slot.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_web_app_slot) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alert_email_addresses"></a> [alert\_email\_addresses](#input\_alert\_email\_addresses) | Email addresses that receive metric alerts (added to a module-managed action group). | `list(string)` | `[]` | no |
| <a name="input_alert_settings"></a> [alert\_settings](#input\_alert\_settings) | Thresholds for the metric alert rules (created when `enable_alerts` is true and `alert_email_addresses` is not empty). | <pre>object({<br>    http_5xx_enabled           = optional(bool, true)<br>    http_5xx_threshold         = optional(number, 10)<br>    http_4xx_enabled           = optional(bool, false)<br>    http_4xx_threshold         = optional(number, 50)<br>    response_time_enabled      = optional(bool, false)<br>    response_time_threshold_ms = optional(number, 1000)<br>    cpu_enabled                = optional(bool, false)<br>    cpu_threshold              = optional(number, 80)<br>  })</pre> | `{}` | no |
| <a name="input_always_on"></a> [always\_on](#input\_always\_on) | Whether the web app is always on. Note: not supported on the free (F1) tier. | `bool` | `false` | no |
| <a name="input_app_command_line"></a> [app\_command\_line](#input\_app\_command\_line) | Custom startup command for the web app. Set to null to use the default. | `string` | `null` | no |
| <a name="input_app_settings"></a> [app\_settings](#input\_app\_settings) | Application settings (environment variables) for the web app. | `map(string)` | `{}` | no |
| <a name="input_application_insights_type"></a> [application\_insights\_type](#input\_application\_insights\_type) | Application type of the Application Insights instance. | `string` | `"web"` | no |
| <a name="input_application_stack"></a> [application\_stack](#input\_application\_stack) | Language stack configuration for Linux web apps. Exactly one of the optional fields should be set (e.g. `node_version = "20-lts"`). Docker stacks use `docker_image` and `docker_image_tag`. Set to null to use the Azure portal default. Ignored when `os_type` is Windows. | <pre>object({<br>    node_version     = optional(string)<br>    python_version   = optional(string)<br>    dotnet_version   = optional(string)<br>    java_version     = optional(string)<br>    php_version      = optional(string)<br>    ruby_version     = optional(string)<br>    docker_image     = optional(string)<br>    docker_image_tag = optional(string)<br>  })</pre> | <pre>{<br>  "node_version": "20-lts"<br>}</pre> | no |
| <a name="input_auth_settings"></a> [auth\_settings](#input\_auth\_settings) | Microsoft Entra ID (AAD) authentication settings (auth_settings_v2). Set to null to disable authentication. When enabled, the client secret is read from the app setting named by `client_secret_setting_name`; use the `client_secret` variable to inject it into app settings. | <pre>object({<br>    enabled                    = bool<br>    client_id                  = string<br>    client_secret_setting_name = string<br>    tenant_auth_endpoint       = string<br>    require_authentication     = optional(bool, true)<br>    unauthenticated_action     = optional(string, "RedirectToLoginPage")<br>    token_store_enabled        = optional(bool, false)<br>  })</pre> | `null` | no |
| <a name="input_backup_settings"></a> [backup\_settings](#input\_backup\_settings) | Backup configuration (requires Standard SKU or higher and a storage account SAS URL). Set to null to disable backups. The `storage_account_url` must be a SAS URL pointing to the backup container. | <pre>object({<br>    storage_account_url      = string<br>    frequency_interval       = optional(number, 1)<br>    frequency_unit           = optional(string, "Day")<br>    retention_period_days    = optional(number, 30)<br>    keep_at_least_one_backup = optional(bool, true)<br>    start_time               = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_certificate_password"></a> [certificate\_password](#input\_certificate\_password) | Password of the PFX certificate passed in `certificate_pfx_blob`. | `string` | `null` | no |
| <a name="input_certificate_pfx_blob"></a> [certificate\_pfx\_blob](#input\_certificate\_pfx\_blob) | Base64-encoded PFX certificate for the custom domain (SNI binding). Set together with `custom_domain`. | `string` | `null` | no |
| <a name="input_client_secret"></a> [client\_secret](#input\_client\_secret) | Client secret for Microsoft Entra authentication. Injected into app settings under `auth_settings.client_secret_setting_name`. Marked sensitive. | `string` | `null` | no |
| <a name="input_connection_strings"></a> [connection\_strings](#input\_connection\_strings) | Connection strings to configure on the web app (Windows only; on Linux use app settings). | <pre>map(object({<br>    type  = string<br>    value = string<br>  }))</pre> | `{}` | no |
| <a name="input_cors_allowed_origins"></a> [cors\_allowed\_origins](#input\_cors\_allowed\_origins) | List of origins allowed to make cross-origin requests to the web app. Use `["*"]` to allow all origins (not recommended for production). | `list(string)` | <pre>[<br>  "*"<br>]</pre> | no |
| <a name="input_cors_support_credentials"></a> [cors\_support\_credentials](#input\_cors\_support\_credentials) | Whether CORS requests with credentials (cookies, HTTP authentication) are allowed. | `bool` | `false` | no |
| <a name="input_create_resource_group"></a> [create\_resource\_group](#input\_create\_resource\_group) | Whether to create the resource group or use an existing one. | `bool` | `true` | no |
| <a name="input_create_user_assigned_identity"></a> [create\_user\_assigned\_identity](#input\_create\_user\_assigned\_identity) | Whether to create a user-assigned managed identity (e.g. for Azure Container Registry pulls or Key Vault references) and assign it to the web app. | `bool` | `false` | no |
| <a name="input_custom_domain"></a> [custom\_domain](#input\_custom\_domain) | Custom hostname to bind to the web app (e.g. `www.example.com`). The CNAME/verification record must already exist in DNS. Set to null to skip. | `string` | `null` | no |
| <a name="input_enable_alerts"></a> [enable\_alerts](#input\_enable\_alerts) | Whether to create metric alert rules for the web app. Requires `alert_email_addresses` (an action group is created from them). | `bool` | `false` | no |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Whether to create Application Insights (workspace-based), a Log Analytics workspace (unless one is provided) and diagnostic settings for the web app. | `bool` | `true` | no |
| <a name="input_enable_private_endpoint"></a> [enable\_private\_endpoint](#input\_enable\_private\_endpoint) | Whether to create a private endpoint so the web app is reachable only from a virtual network. Requires a Premium v2/v3 SKU and `private_endpoint_subnet_id`. | `bool` | `false` | no |
| <a name="input_enable_staging_slot"></a> [enable\_staging\_slot](#input\_enable\_staging\_slot) | Whether to create a staging deployment slot for zero-downtime deployments. | `bool` | `false` | no |
| <a name="input_enable_system_assigned_identity"></a> [enable\_system\_assigned\_identity](#input\_enable\_system\_assigned\_identity) | Whether to assign a system-assigned managed identity to the web app. | `bool` | `false` | no |
| <a name="input_ftps_state"></a> [ftps\_state](#input\_ftps\_state) | State of FTPS deployment: AllAllowed, FtpsOnly or Disabled. | `string` | `"FtpsOnly"` | no |
| <a name="input_health_check_eviction_time_in_min"></a> [health\_check\_eviction\_time\_in\_min](#input\_health\_check\_eviction\_time\_in\_min) | Minutes a node can stay unhealthy before being removed from the load balancer (2-10). Only valid together with `health_check_path`. | `number` | `null` | no |
| <a name="input_health_check_path"></a> [health\_check\_path](#input\_health\_check\_path) | Path used for the App Service health check (e.g. `/healthz`). Set to null to disable. | `string` | `null` | no |
| <a name="input_http2_enabled"></a> [http2\_enabled](#input\_http2\_enabled) | Whether to enable HTTP/2 for the web app. | `bool` | `true` | no |
| <a name="input_https_only"></a> [https\_only](#input\_https\_only) | Whether to redirect all HTTP traffic to HTTPS. | `bool` | `true` | no |
| <a name="input_ip_restrictions"></a> [ip\_restrictions](#input\_ip\_restrictions) | IP access restrictions for the main site. Each rule supports: `name`, `priority` (1-65536, lower wins), `action` (Allow/Deny), and one of `ip_address` (CIDR), `service_tag` or `virtual_network_subnet_id`. | <pre>list(object({<br>    name                      = string<br>    priority                  = number<br>    action                    = optional(string, "Allow")<br>    ip_address                = optional(string)<br>    service_tag               = optional(string)<br>    virtual_network_subnet_id = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region in which to create the resources. | `string` | n/a | yes |
| <a name="input_log_analytics_retention_in_days"></a> [log\_analytics\_retention\_in\_days](#input\_log\_analytics\_retention\_in\_days) | Retention in days of the Log Analytics workspace created by the module (30-730). | `number` | `30` | no |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | ID of an existing Log Analytics workspace. When null and monitoring is enabled, the module creates one. | `string` | `null` | no |
| <a name="input_log_analytics_workspace_sku"></a> [log\_analytics\_workspace\_sku](#input\_log\_analytics\_workspace\_sku) | SKU of the Log Analytics workspace created by the module. | `string` | `"PerGB2018"` | no |
| <a name="input_maximum_elastic_worker_count"></a> [maximum\_elastic\_worker\_count](#input\_maximum\_elastic\_worker\_count) | Maximum number of workers for Elastic/Premium plan auto-scale. Only valid with Elastic (EP) or Premium plans with auto-scaling enabled. | `number` | `null` | no |
| <a name="input_minimum_tls_version"></a> [minimum\_tls\_version](#input\_minimum\_tls\_version) | Minimum TLS version for the web app. | `string` | `"1.2"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the web app. Must be globally unique within Azure. | `string` | n/a | yes |
| <a name="input_os_type"></a> [os\_type](#input\_os\_type) | Operating system of the web app: Linux or Windows. | `string` | `"Linux"` | no |
| <a name="input_per_site_scaling_enabled"></a> [per\_site\_scaling\_enabled](#input\_per\_site\_scaling\_enabled) | Whether per-site scaling is enabled on the App Service plan. | `bool` | `false` | no |
| <a name="input_private_dns_zone_id"></a> [private\_dns\_zone\_id](#input\_private\_dns\_zone\_id) | ID of an existing private DNS zone (`privatelink.azurewebsites.net`). When null, the module creates and manages the zone. | `string` | `null` | no |
| <a name="input_private_endpoint_subnet_id"></a> [private\_endpoint\_subnet\_id](#input\_private\_endpoint\_subnet\_id) | ID of the subnet in which to create the private endpoint. Required when `enable_private_endpoint` is true. | `string` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether public network access is enabled for the web app. Defaults to false when a private endpoint is enabled, true otherwise. | `bool` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group. Created when `create_resource_group` is true, otherwise looked up. | `string` | n/a | yes |
| <a name="input_scm_ip_restrictions"></a> [scm\_ip\_restrictions](#input\_scm\_ip\_restrictions) | IP access restrictions for the SCM (Kudu) endpoint. Same rule format as `ip_restrictions`. The SCM endpoint is already private when a private endpoint is enabled. | <pre>list(object({<br>    name                      = string<br>    priority                  = number<br>    action                    = optional(string, "Allow")<br>    ip_address                = optional(string)<br>    service_tag               = optional(string)<br>    virtual_network_subnet_id = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_scm_use_main_ip_restriction"></a> [scm\_use\_main\_ip\_restriction](#input\_scm\_use\_main\_ip\_restriction) | Whether the SCM endpoint should use the same restrictions as the main site. | `bool` | `false` | no |
| <a name="input_service_plan_name"></a> [service\_plan\_name](#input\_service\_plan\_name) | Name of the App Service plan. Defaults to `<name>-plan` when null. | `string` | `null` | no |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | SKU of the App Service plan (e.g. F1, B1, S1, P1v2, P1v3). Private endpoints require Premium v2/v3; zone redundancy requires Premium v2/v3 with at least 3 workers. | `string` | `"F1"` | no |
| <a name="input_staging_slot_name"></a> [staging\_slot\_name](#input\_staging\_slot\_name) | Name of the staging deployment slot. | `string` | `"staging"` | no |
| <a name="input_sticky_app_setting_names"></a> [sticky\_app\_setting\_names](#input\_sticky\_app\_setting\_names) | App setting names that must not be swapped between deployment slots. | `list(string)` | `[]` | no |
| <a name="input_sticky_connection_string_names"></a> [sticky\_connection\_string\_names](#input\_sticky\_connection\_string\_names) | Connection string names that must not be swapped between deployment slots (Windows only). | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all supported resources. | `map(string)` | `{}` | no |
| <a name="input_user_assigned_identity_ids"></a> [user\_assigned\_identity\_ids](#input\_user\_assigned\_identity\_ids) | IDs of existing user-assigned managed identities to assign to the web app. | `list(string)` | `[]` | no |
| <a name="input_user_assigned_identity_name"></a> [user\_assigned\_identity\_name](#input\_user\_assigned\_identity\_name) | Name of the user-assigned identity created when `create_user_assigned_identity` is true. Defaults to `<name>-uai`. | `string` | `null` | no |
| <a name="input_virtual_network_id"></a> [virtual\_network\_id](#input\_virtual\_network\_id) | ID of the virtual network to link to the private DNS zone (for name resolution). Required when the module creates the zone. When an existing zone is used, only set this if the zone lives in the web app's resource group (the module creates the VNet link there); otherwise link your VNet to the zone yourself and leave this null. | `string` | `null` | no |
| <a name="input_vnet_integration_subnet_id"></a> [vnet\_integration\_subnet\_id](#input\_vnet\_integration\_subnet\_id) | ID of a subnet delegated to Microsoft.Web/serverFarms for regional VNet integration (outbound traffic). Set to null to disable. | `string` | `null` | no |
| <a name="input_vnet_route_all_enabled"></a> [vnet\_route\_all\_enabled](#input\_vnet\_route\_all\_enabled) | Whether all outbound traffic should go through the VNet (NAT/NSG/UDR applied). | `bool` | `false` | no |
| <a name="input_windows_application_stack"></a> [windows\_application\_stack](#input\_windows\_application\_stack) | Application stack configuration for Windows web apps. `current_stack` should be one of dotnet, dotnetcore, node, python, php or java. Docker containers use `docker_image_name` (+ registry settings). Set to null to use the Azure portal default. Ignored when `os_type` is Linux. | <pre>object({<br>    current_stack                = optional(string)<br>    docker_image_name            = optional(string)<br>    docker_registry_url          = optional(string)<br>    docker_registry_username     = optional(string)<br>    docker_registry_password     = optional(string)<br>    dotnet_version               = optional(string)<br>    dotnet_core_version          = optional(string)<br>    java_version                 = optional(string)<br>    java_embedded_server_enabled = optional(bool)<br>    tomcat_version               = optional(string)<br>    node_version                 = optional(string)<br>    php_version                  = optional(string)<br>    python                       = optional(bool)<br>  })</pre> | `null` | no |
| <a name="input_worker_count"></a> [worker\_count](#input\_worker\_count) | Number of workers (instances) allocated to the plan and web app. Raised to 3 when `zone_redundant` is true. | `number` | `1` | no |
| <a name="input_zone_redundant"></a> [zone\_redundant](#input\_zone\_redundant) | Whether the App Service plan should balance across availability zones (Premium v2/v3 SKUs, minimum 3 workers). | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_action_group_id"></a> [action\_group\_id](#output\_action\_group\_id) | ID of the alert action group created by the module. Null when alerts are disabled or no email addresses are configured. |
| <a name="output_application_insights_connection_string"></a> [application\_insights\_connection\_string](#output\_application\_insights\_connection\_string) | Connection string of the Application Insights instance (also injected into app settings). Null when monitoring is disabled. |
| <a name="output_application_insights_id"></a> [application\_insights\_id](#output\_application\_insights\_id) | ID of the Application Insights instance. Null when monitoring is disabled. |
| <a name="output_application_insights_instrumentation_key"></a> [application\_insights\_instrumentation\_key](#output\_application\_insights\_instrumentation\_key) | Instrumentation key of the Application Insights instance. Null when monitoring is disabled. |
| <a name="output_certificate_id"></a> [certificate\_id](#output\_certificate\_id) | ID of the TLS certificate uploaded for the custom domain. Null when no certificate is provided. |
| <a name="output_certificate_thumbprint"></a> [certificate\_thumbprint](#output\_certificate\_thumbprint) | Thumbprint of the TLS certificate bound to the custom domain. Null when no certificate is provided. |
| <a name="output_cors_configuration_id"></a> [cors\_configuration\_id](#output\_cors\_configuration\_id) | ID of the CORS configuration managed via azapi. |
| <a name="output_custom_domain_binding_id"></a> [custom\_domain\_binding\_id](#output\_custom\_domain\_binding\_id) | ID of the custom hostname binding. Null when `custom_domain` is not set. |
| <a name="output_default_hostname"></a> [default\_hostname](#output\_default\_hostname) | Default hostname of the web app, e.g. `<name>.azurewebsites.net`. |
| <a name="output_diagnostic_setting_id"></a> [diagnostic\_setting\_id](#output\_diagnostic\_setting\_id) | ID of the diagnostic setting sending web app logs and metrics to Log Analytics. Null when monitoring is disabled. |
| <a name="output_identity_principal_id"></a> [identity\_principal\_id](#output\_identity\_principal\_id) | Principal (object) ID of the system-assigned managed identity. Null when `enable_system_assigned_identity` is false. |
| <a name="output_identity_type"></a> [identity\_type](#output\_identity\_type) | Managed identity type assigned to the web app (null when no identity is configured). |
| <a name="output_location"></a> [location](#output\_location) | Azure region of the deployed resources. |
| <a name="output_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#output\_log\_analytics\_workspace\_id) | ID of the Log Analytics workspace used for diagnostics. Null when monitoring is disabled. |
| <a name="output_metric_alert_id"></a> [metric\_alert\_id](#output\_metric\_alert\_id) | ID of the metric alert rule. Null when alerts are disabled or no criteria are enabled. |
| <a name="output_outbound_ip_addresses"></a> [outbound\_ip\_addresses](#output\_outbound\_ip\_addresses) | List of outbound IP addresses of the web app. |
| <a name="output_private_dns_zone_id"></a> [private\_dns\_zone\_id](#output\_private\_dns\_zone\_id) | ID of the private DNS zone used for the private endpoint. Null when `enable_private_endpoint` is false. |
| <a name="output_private_endpoint_id"></a> [private\_endpoint\_id](#output\_private\_endpoint\_id) | ID of the private endpoint. Null when `enable_private_endpoint` is false. |
| <a name="output_private_endpoint_private_ip_address"></a> [private\_endpoint\_private\_ip\_address](#output\_private\_endpoint\_private\_ip\_address) | Primary private IP address of the private endpoint. Null when `enable_private_endpoint` is false. (The SCM endpoint receives a second IP registered in the private DNS zone.) |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the resource group hosting the web app. |
| <a name="output_service_plan_id"></a> [service\_plan\_id](#output\_service\_plan\_id) | ID of the App Service plan. |
| <a name="output_service_plan_name"></a> [service\_plan\_name](#output\_service\_plan\_name) | Name of the App Service plan. |
| <a name="output_staging_slot_default_hostname"></a> [staging\_slot\_default\_hostname](#output\_staging\_slot\_default\_hostname) | Default hostname of the staging deployment slot. Null when `enable_staging_slot` is false. |
| <a name="output_user_assigned_identity_client_id"></a> [user\_assigned\_identity\_client\_id](#output\_user\_assigned\_identity\_client\_id) | Client ID of the user-assigned identity created by the module. Null when `create_user_assigned_identity` is false. |
| <a name="output_user_assigned_identity_id"></a> [user\_assigned\_identity\_id](#output\_user\_assigned\_identity\_id) | ID of the user-assigned identity created by the module. Null when `create_user_assigned_identity` is false. |
| <a name="output_user_assigned_identity_principal_id"></a> [user\_assigned\_identity\_principal\_id](#output\_user\_assigned\_identity\_principal\_id) | Principal (object) ID of the user-assigned identity created by the module. Null when `create_user_assigned_identity` is false. |
| <a name="output_vnet_integration_connection_id"></a> [vnet\_integration\_connection\_id](#output\_vnet\_integration\_connection\_id) | ID of the regional VNet integration (swift) connection. Null when `vnet_integration_subnet_id` is not set. |
| <a name="output_web_app_id"></a> [web\_app\_id](#output\_web\_app\_id) | ID of the web app. |
| <a name="output_web_app_name"></a> [web\_app\_name](#output\_web\_app\_name) | Name of the web app. |
| <a name="output_web_app_os_type"></a> [web\_app\_os\_type](#output\_web\_app\_os\_type) | Operating system of the web app (Linux or Windows). |
| <a name="output_web_app_url"></a> [web\_app\_url](#output\_web\_app\_url) | HTTPS URL of the web app. |
<!-- END_TF_DOCS -->
