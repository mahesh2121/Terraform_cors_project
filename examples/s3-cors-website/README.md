# Example: S3 CORS static website

Complete root module that consumes
[`modules/s3-cors-website`](../../modules/s3-cors-website) to provision a
public S3 bucket hosting the CORS test page in [`www/`](www) with CORS rules,
versioning and a public-read policy.

## Prerequisites

- AWS credentials (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`, or an AWS
  profile)
- An S3 bucket + DynamoDB table for the Terraform state (see
  `backend.s3.hcl.example`)

## Usage

```sh
cd examples/s3-cors-website

cp terraform.tfvars.example terraform.tfvars     # edit the bucket name (must be unique)
cp backend.s3.hcl.example backend.s3.hcl         # edit the state backend values

terraform init -backend-config=backend.s3.hcl
terraform plan
terraform apply
```

After `apply`, open the `website_url` output and click **Fetch via CORS**.
The page fetches itself through the S3 REST endpoint (a different origin than
the website endpoint), proving the CORS configuration works.

## Cleaning up

```sh
terraform destroy
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket_name | Name of the S3 bucket (must be globally unique). | `string` | n/a | yes |
| region | AWS region in which to create the bucket. | `string` | `"ap-south-1"` | no |
| cors_allowed_origins | Origins allowed to make cross-origin requests to the bucket. | `list(string)` | `["*"]` | no |
| tags | Map of tags to apply to the bucket. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | ID (name) of the S3 bucket. |
| website_endpoint | S3 static website endpoint. |
| website_url | Full HTTPS URL of the website index document. |
| website_object_urls | Map of uploaded object keys to their HTTPS URLs. |
