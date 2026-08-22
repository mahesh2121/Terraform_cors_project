# Example: Windows web app — full feature test

Dedicated example folder that exercises **every feature** of
[`modules/azure-webapp-cors`](../../modules/azure-webapp-cors) on a
**Windows** web app. This is the test/demo deployment: copy
`terraform.tfvars.example` to `terraform.tfvars`, fill in the marked
placeholders, and everything gets enabled.

## Features tested

| # | Feature | How it is enabled here |
| - | ------- | ---------------------- |
| 1 | Windows web app | `os_type = "Windows"`, Node `~20` stack |
| 2 | Zone redundancy | `zone_redundant = true`, `worker_count = 3` (Premium v2/v3) |
| 3 | Per-site scaling | `per_site_scaling_enabled = true` |
| 4 | App settings | `app_settings` (incl. `DATABASE_URL`) |
| 5 | Connection strings (Windows) | `connection_strings` (`DefaultConnection` SQLAzure) |
| 6 | Health check + eviction | `/healthz`, eviction after 2 min |
| 7 | Staging slot | `enable_staging_slot = true` |
| 8 | Sticky settings | `DATABASE_URL` app setting + `DefaultConnection` connection string pinned to slots |
| 9 | IP restrictions | site + SCM rules, `scm_use_main_ip_restriction = true` |
| 10 | Private endpoint | dedicated subnet; site becomes **private-only** |
| 11 | Private DNS zone | module-managed `privatelink.azurewebsites.net` + VNet link |
| 12 | VNet integration | delegated `Microsoft.Web/serverFarms` subnet, all outbound traffic through VNet |
| 13 | System-assigned identity | `enable_system_assigned_identity = true` |
| 14 | User-assigned identity | `create_user_assigned_identity = true` |
| 15 | Entra authentication | `auth_settings` + client secret injected into app settings |
| 16 | Backups | scheduled backup to a storage container (SAS URL) |
| 17 | Custom domain + TLS | hostname binding + PFX SNI certificate |
| 18 | Monitoring | workspace-based Application Insights + Log Analytics + diagnostic settings |
| 19 | Alerts | Http5xx/4xx, response time, CPU rules → email action group |
| 20 | CORS | allowed origins via `azapi` |

## Prerequisites

- Azure subscription; authenticate via Azure CLI (`az login`) or service
  principal (`ARM_*` environment variables)
- Azure Storage account + container for the Terraform state
  (see `backend.azurerm.hcl.example`)
- For feature 15: an Entra app registration (client ID, secret, tenant)
- For feature 16: a storage container + SAS URL
- For feature 17: a DNS CNAME to the app + a PFX certificate
- Premium v2/v3 plan (example uses zone-redundant `P1v3`) — **note the cost**

## Deploy

```sh
cd examples/azure-webapp-cors-windows

cp terraform.tfvars.example terraform.tfvars          # fill the placeholders
cp backend.azurerm.hcl.example backend.azurerm.hcl    # state backend values

terraform init -backend-config=backend.azurerm.hcl
terraform plan
terraform apply
```

## Test checklist

Run these checks after `apply`. HTTP checks must run from a machine inside
the virtual network (the site is private-only); use `az webapp` commands from
anywhere with the Azure CLI logged in.

```sh
APP=my-windows-webapp
RG=rg-my-windows-webapp

# 1-2. Windows + zone redundancy
az webapp show -g "$RG" -n "$APP" --query "{os:kind, host:defaultHostName}"
az appservice plan show -g "$RG" -n "$APP-plan" --query "{zoneRedundant:zoneRedundant, workers:capacity}"

# 5. Connection strings
az webapp config connection-string list -g "$RG" -n "$APP"

# 6. Health check (from inside the VNet)
curl -i https://$APP.azurewebsites.net/healthz        # HTTP 200

# 7. Staging slot
az webapp deployment slot list -g "$RG" -n "$APP" --query "[].name"

# 9. IP restrictions
az webapp config access-restriction show -g "$RG" -n "$APP"

# 10-12. Private endpoint + DNS + VNet integration (from inside the VNet)
nslookup $APP.azurewebsites.net                       # -> 10.10.x private IP
az webapp show -g "$RG" -n "$APP" --query virtualNetworkSubnetId
az network private-endpoint list -g "$RG" --query "[].name"

# 13-14. Managed identities
az webapp identity show -g "$RG" -n "$APP"
az identity list -g "$RG" --query "[].{name:name, clientId:clientId}"

# 15. Entra authentication: anonymous request is redirected to the login page
curl -i https://$APP.azurewebsites.net                # HTTP 302 -> login.microsoftonline.com

# 16. Backups
az webapp config backup list -g "$RG" -n "$APP"

# 17. Custom domain + TLS
az webapp config hostname list -g "$RG" --webapp-name "$APP"
az webapp config ssl list -g "$RG" --query "[].thumbprint"

# 18. Monitoring
az monitor app-insights component show -g "$RG" -a "$APP-ai" --query "{id:id, type:applicationType}"
az monitor diagnostic-settings list --resource "$(az webapp show -g "$RG" -n "$APP" --query id -o tsv)"

# 19. Alerts
az monitor metrics alert list -g "$RG" --query "[].name"

# 20. CORS preflight (from inside the VNet)
curl -i -X OPTIONS \
  -H "Origin: https://app.example.com" \
  -H "Access-Control-Request-Method: GET" \
  https://$APP.azurewebsites.net                     # -> Access-Control-Allow-Origin
```

## Cleaning up

```sh
terraform destroy
```

## Outputs

`terraform output` exposes: `web_app_url`, `default_hostname`,
`service_plan_name`, `identity_principal_id`,
`user_assigned_identity_client_id`, `private_endpoint_id`,
`private_endpoint_private_ip_address`, `private_dns_zone_id`,
`vnet_integration_connection_id`, `staging_slot_default_hostname`,
`custom_domain_binding_id`, `certificate_thumbprint`,
`application_insights_id`, `application_insights_connection_string`,
`log_analytics_workspace_id`, `action_group_id`, `metric_alert_id`.
