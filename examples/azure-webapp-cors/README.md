# Example: Azure Web App with CORS

Complete root module that consumes
[`modules/azure-webapp-cors`](../../modules/azure-webapp-cors) to provision a
Linux App Service web app with CORS allowed origins configured via `azapi`.

## Prerequisites

- Azure subscription; authenticate with one of:
  - Azure CLI (`az login`) and environment variables (`ARM_SUBSCRIPTION_ID`,
    `ARM_TENANT_ID`)
  - A service principal (`ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`,
    `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`)
- An Azure Storage account + container for the Terraform state (see
  `backend.azurerm.hcl.example`)

## Usage

```sh
cd examples/azure-webapp-cors

cp terraform.tfvars.example terraform.tfvars          # edit the app name (must be unique)
cp backend.azurerm.hcl.example backend.azurerm.hcl    # edit the state backend values

terraform init -backend-config=backend.azurerm.hcl
terraform plan
terraform apply
```

## Verifying CORS

```sh
curl -i -X OPTIONS \
  -H "Origin: https://my-frontend.example.com" \
  -H "Access-Control-Request-Method: GET" \
  https://my-cors-webapp.azurewebsites.net
```

The response must include `Access-Control-Allow-Origin` matching the origin
you configured in `cors_allowed_origins`.

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
| sku_name | SKU of the App Service plan. | `string` | `"F1"` | no |
| application_stack | Language stack configuration (see module README). | `map(string)` | `{"node_version": "20-lts"}` | no |
| app_settings | Application settings (environment variables) for the web app. | `map(string)` | `{"WEBSITE_NODE_DEFAULT_VERSION": "20-lts"}` | no |
| cors_allowed_origins | Origins allowed to make cross-origin requests to the web app. | `list(string)` | `["*"]` | no |
| tags | Map of tags to apply to the resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| web_app_url | HTTPS URL of the web app. |
| default_hostname | Default hostname of the web app. |
| resource_group_name | Name of the resource group hosting the web app. |
