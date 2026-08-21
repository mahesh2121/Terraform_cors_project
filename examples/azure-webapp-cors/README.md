# Example: Azure Web App (Windows) with private endpoint, Entra auth and CORS

Complete root module that consumes
[`modules/azure-webapp-cors`](../../modules/azure-webapp-cors) to provision a
**Windows** App Service web app with:

- a **private endpoint** (Premium SKU) in a dedicated VNet/subnet with a
  managed `privatelink.azurewebsites.net` private DNS zone,
- **Microsoft Entra ID authentication** (optional, enabled via variables),
- a **system-assigned managed identity**,
- **CORS** allowed origins configured via `azapi`.

The web app is **private-only** by default (`public_network_access_enabled`
defaults to false when the private endpoint is enabled), so it is reachable
only from within the virtual network (or peered networks).

## Prerequisites

- Azure subscription; authenticate with one of:
  - Azure CLI (`az login`) and environment variables (`ARM_SUBSCRIPTION_ID`,
    `ARM_TENANT_ID`)
  - A service principal (`ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`,
    `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`)
- An Azure Storage account + container for the Terraform state (see
  `backend.azurerm.hcl.example`)
- An Entra app registration (client ID/secret/tenant) if `enable_auth` is true
- Premium v2/v3 App Service plan (the example uses `P1v3`) — note the cost

## Usage

```sh
cd examples/azure-webapp-cors

cp terraform.tfvars.example terraform.tfvars          # edit the app name (must be unique)
cp backend.azurerm.hcl.example backend.azurerm.hcl    # edit the state backend values

terraform init -backend-config=backend.azurerm.hcl
terraform plan
terraform apply
```

## Verifying

From a machine inside the virtual network:

```sh
# DNS resolution of the private endpoint
nslookup my-private-webapp.azurewebsites.net
# Expected: a 10.10.0.x address registered by the private DNS zone

# Authentication: the web app answers 302 -> Entra login for anonymous requests
curl -i https://my-private-webapp.azurewebsites.net

# CORS preflight
curl -i -X OPTIONS \
  -H "Origin: https://my-frontend.example.com" \
  -H "Access-Control-Request-Method: GET" \
  https://my-private-webapp.azurewebsites.net
```

## Cleaning up

```sh
terraform destroy
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| app_name | Name of the web app (must be globally unique within Azure). | `string` | n/a | yes |
| resource_group_name | Name of the resource group to create. | `string` | n/a | yes |
| location | Azure region in which to create the resources. | `string` | `"eastus"` | no |
| os_type | Operating system of the web app: Linux or Windows. | `string` | `"Windows"` | no |
| sku_name | SKU of the App Service plan. Private endpoints require Premium v2/v3 (e.g. P1v3). | `string` | `"P1v3"` | no |
| linux_application_stack | Language stack for Linux web apps. Used when os_type is Linux. | `object(…)` | `{}` | no |
| windows_application_stack | Application stack for Windows web apps. Used when os_type is Windows. | `object(…)` | `{}` | no |
| app_settings | Application settings (environment variables) for the web app. | `map(string)` | `{}` | no |
| cors_allowed_origins | Origins allowed to make cross-origin requests to the web app. | `list(string)` | `["*"]` | no |
| enable_private_endpoint | Whether to create a private endpoint (site becomes private-only by default). | `bool` | `true` | no |
| virtual_network_address_space | Address space of the virtual network hosting the private endpoint. | `list(string)` | `["10.10.0.0/24"]` | no |
| private_endpoint_subnet_prefixes | Address prefixes of the private endpoint subnet. | `list(string)` | `["10.10.0.0/27"]` | no |
| enable_system_assigned_identity | Whether to assign a system-assigned managed identity to the web app. | `bool` | `true` | no |
| enable_auth | Whether to enable Microsoft Entra ID authentication. | `bool` | `false` | no |
| auth_client_id | Client ID of the Entra app registration. Required when enable_auth is true. | `string` | `null` | no |
| auth_client_secret | Client secret of the Entra app registration (stored in an app setting). | `string` | `null` | no |
| auth_client_secret_setting_name | App setting name that holds the Entra client secret. | `string` | `"MICROSOFT_PROVIDER_AUTHENTICATION_SECRET"` | no |
| auth_tenant_id | Tenant ID used for the Entra authentication endpoint. | `string` | `null` | no |
| auth_unauthenticated_action | Action for unauthenticated requests. | `string` | `"RedirectToLoginPage"` | no |
| tags | Map of tags to apply to the resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| web_app_url | HTTPS URL of the web app. |
| default_hostname | Default hostname of the web app. |
| resource_group_name | Name of the resource group hosting the web app. |
| web_app_os_type | Operating system of the web app. |
| identity_principal_id | Principal ID of the system-assigned managed identity. |
| private_endpoint_id | ID of the private endpoint (null when disabled). |
| private_endpoint_private_ip_address | Primary private IP address of the private endpoint (null when disabled). |
| private_dns_zone_id | ID of the private DNS zone (null when private endpoint is disabled). |
