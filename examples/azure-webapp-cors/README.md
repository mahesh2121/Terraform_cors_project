# Example: Production-ready Azure Web App (Windows) with CORS

Complete root module that consumes
[`modules/azure-webapp-cors`](../../modules/azure-webapp-cors) to provision a
**production-grade** App Service web app:

| Feature | Configuration |
| ------- | ------------- |
| OS | Windows or Linux (`os_type`) |
| High availability | Zone-redundant Premium plan (`zone_redundant`, 3 workers) |
| Private access | Private endpoint + `privatelink.azurewebsites.net` DNS zone; site is private-only by default |
| Outbound networking | Regional VNet integration via a `Microsoft.Web/serverFarms`-delegated subnet, all traffic routed through the VNet |
| Zero-downtime deploys | Staging deployment slot + sticky settings |
| Health checking | `/healthz` with node eviction |
| Access control | IP restrictions for site & SCM (`scm_use_main_ip_restriction`) |
| Authentication | Microsoft Entra ID (optional, via variables) |
| Identity | System-assigned + module-created user-assigned identity (Key Vault / ACR ready) |
| Backups | Scheduled web app backup (optional, SAS URL) |
| Custom domain | Hostname binding + PFX SNI certificate (optional) |
| Observability | Workspace-based Application Insights, Log Analytics, diagnostic settings, metric alerts (Http5xx/CPU) to email |
| CORS | `azapi`-managed allowed origins |

## Prerequisites

- Azure subscription; authenticate with one of:
  - Azure CLI (`az login`) and environment variables (`ARM_SUBSCRIPTION_ID`,
    `ARM_TENANT_ID`)
  - A service principal (`ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`,
    `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`)
- An Azure Storage account + container for the Terraform state (see
  `backend.azurerm.hcl.example`)
- An Entra app registration (client ID/secret/tenant) if `enable_auth` is true
- Premium v2/v3 App Service plan (the example uses zone-redundant `P1v3`) —
  note the cost

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
nslookup my-prod-webapp.azurewebsites.net
# Expected: a 10.10.x address registered by the private DNS zone

# Health check
curl -i https://my-prod-webapp.azurewebsites.net/healthz

# Authentication (when enabled): the web app answers 302 -> Entra login
curl -i https://my-prod-webapp.azurewebsites.net

# CORS preflight
curl -i -X OPTIONS \
  -H "Origin: https://app.example.com" \
  -H "Access-Control-Request-Method: GET" \
  https://my-prod-webapp.azurewebsites.net
```

## Cleaning up

```sh
terraform destroy
```

## Inputs

See `variables.tf` — the full set includes OS/stacks, high availability,
networking (private endpoint + VNet integration), deployment slots, access
restrictions, identities, Entra auth, backups, custom domain, monitoring,
alerts and CORS. All sensitive values (`auth_client_secret`,
`certificate_pfx_blob`, `certificate_password`) are marked `sensitive`.

## Outputs

| Name | Description |
|------|-------------|
| web_app_url | HTTPS URL of the web app. |
| default_hostname | Default hostname of the web app. |
| resource_group_name | Name of the resource group hosting the web app. |
| web_app_os_type | Operating system of the web app. |
| identity_principal_id | Principal ID of the system-assigned managed identity. |
| user_assigned_identity_client_id | Client ID of the user-assigned managed identity. |
| private_endpoint_id | ID of the private endpoint. |
| private_endpoint_private_ip_address | Primary private IP address of the private endpoint. |
| private_dns_zone_id | ID of the private DNS zone. |
| staging_slot_default_hostname | Default hostname of the staging deployment slot. |
| application_insights_id | ID of the Application Insights instance. |
| log_analytics_workspace_id | ID of the Log Analytics workspace. |
| metric_alert_id | ID of the metric alert rule. |
