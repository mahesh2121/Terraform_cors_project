# S3 CORS static website module

Standardized Terraform module that provisions an Amazon S3 bucket configured as
a public static website with [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
rules, optional content upload, bucket versioning, and a public-read bucket
policy.

## Features

- Static website hosting (`index` / optional `error` document)
- Fully configurable, multiple CORS rules (`allowed_origins`, `allowed_methods`, ...)
- Optional upload of a local directory (`website_files_path`) with correct `content_type`
- Versioning, `BucketOwnerEnforced` ownership, and public access block settings
- Public-read bucket policy (optional, on by default) with support for additional statements

## Usage

```hcl
module "s3_cors_website" {
  source = "github.com/mahesh2121/Terraform_cors_project//modules/s3-cors-website?ref=modules/s3-cors-website/v1.0.0"

  name = "my-cors-enabled-bucket-12345"

  cors_rules = [{
    id              = "allow-get-from-anywhere"
    allowed_origins = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }]

  website_files_path = "www"   # relative to the calling root module
  tags               = { Project = "terraform-cors-project" }
}
```

> **Note:** `website_files_path` is resolved relative to the calling root
> module (`path.root`). See [`examples/s3-cors-website`](../../examples/s3-cors-website)
> for a complete, runnable example.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.67, < 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.67, < 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_cors_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_website_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration) | resource |
| [aws_s3_object.website_files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_bucket_policy_statements"></a> [additional\_bucket\_policy\_statements](#input\_additional\_bucket\_policy\_statements) | Additional IAM policy statements (in Terraform object form) to merge into the bucket policy. | `list(any)` | `[]` | no |
| <a name="input_block_public_acls"></a> [block\_public\_acls](#input\_block\_public\_acls) | Whether Amazon S3 should block public ACLs for this bucket. | `bool` | `true` | no |
| <a name="input_block_public_policy"></a> [block\_public\_policy](#input\_block\_public\_policy) | Whether Amazon S3 should block public bucket policies for this bucket. Must be false when `enable_public_read` is true. | `bool` | `false` | no |
| <a name="input_cors_rules"></a> [cors\_rules](#input\_cors\_rules) | List of CORS rules to apply to the bucket. Each rule supports:<br>- `id`: rule identifier (optional)<br>- `allowed_origins`: origins allowed to make cross-origin requests (use `["*"]` to allow all)<br>- `allowed_methods`: HTTP methods allowed<br>- `allowed_headers`: headers allowed in preflight requests<br>- `expose_headers`: headers browsers are allowed to read<br>- `max_age_seconds`: how long (seconds) browsers may cache the preflight response | <pre>list(object({<br>    id              = optional(string)<br>    allowed_origins = list(string)<br>    allowed_methods = list(string)<br>    allowed_headers = optional(list(string), ["*"])<br>    expose_headers  = optional(list(string), [])<br>    max_age_seconds = optional(number, 3000)<br>  }))</pre> | <pre>[<br>  {<br>    "allowed_methods": [<br>      "GET",<br>      "HEAD"<br>    ],<br>    "allowed_origins": [<br>      "*"<br>    ]<br>  }<br>]</pre> | no |
| <a name="input_enable_public_read"></a> [enable\_public\_read](#input\_enable\_public\_read) | Whether to attach a bucket policy granting public read access (`s3:GetObject`) to all objects. Required for a public CORS-enabled website; set to false to keep the bucket private. | `bool` | `true` | no |
| <a name="input_enable_static_website"></a> [enable\_static\_website](#input\_enable\_static\_website) | Whether to configure the bucket as a static website (index/error documents). | `bool` | `true` | no |
| <a name="input_error_document"></a> [error\_document](#input\_error\_document) | Object key that serves as the website error document. Set to null to disable. | `string` | `null` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Whether to allow deletion of the bucket and all objects when running `terraform destroy`. Only enable for non-production environments. | `bool` | `false` | no |
| <a name="input_ignore_public_acls"></a> [ignore\_public\_acls](#input\_ignore\_public\_acls) | Whether Amazon S3 should ignore public ACLs for this bucket. | `bool` | `true` | no |
| <a name="input_index_document"></a> [index\_document](#input\_index\_document) | Object key that serves as the website index document. | `string` | `"index.html"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the S3 bucket. Must be globally unique, 3-63 characters, lowercase letters, numbers, dots and hyphens. | `string` | n/a | yes |
| <a name="input_restrict_public_buckets"></a> [restrict\_public\_buckets](#input\_restrict\_public\_buckets) | Whether Amazon S3 should restrict public bucket policies for this bucket. Must be false when `enable_public_read` is true. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all supported resources. | `map(string)` | `{}` | no |
| <a name="input_versioning_enabled"></a> [versioning\_enabled](#input\_versioning\_enabled) | Whether to enable S3 bucket versioning. | `bool` | `true` | no |
| <a name="input_website_files_path"></a> [website\_files\_path](#input\_website\_files\_path) | Path (relative to the caller's root module) of a directory whose contents are uploaded to the bucket. Set to null to skip uploads. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the S3 bucket. |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | Bucket domain name, e.g. `<name>.s3.amazonaws.com`. |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | ID (name) of the S3 bucket. |
| <a name="output_bucket_policy_id"></a> [bucket\_policy\_id](#output\_bucket\_policy\_id) | ID of the bucket policy (only when `enable_public_read` is true). |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | Regional bucket domain name, e.g. `<name>.s3.<region>.amazonaws.com`. |
| <a name="output_cors_configuration_id"></a> [cors\_configuration\_id](#output\_cors\_configuration\_id) | ID of the S3 bucket CORS configuration. |
| <a name="output_website_endpoint"></a> [website\_endpoint](#output\_website\_endpoint) | S3 static website endpoint (only when `enable_static_website` is true). |
| <a name="output_website_object_urls"></a> [website\_object\_urls](#output\_website\_object\_urls) | Map of uploaded object keys to their HTTPS URLs. |
| <a name="output_website_url"></a> [website\_url](#output\_website\_url) | Full HTTPS URL of the website index document (only when `enable_static_website` is true). |
<!-- END_TF_DOCS -->
