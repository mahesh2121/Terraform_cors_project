variable "name" {
  description = "Name of the S3 bucket. Must be globally unique, 3-63 characters, lowercase letters, numbers, dots and hyphens."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.name)) && length(var.name) >= 3 && length(var.name) <= 63
    error_message = "Bucket name must be 3-63 characters long, contain only lowercase letters, numbers, dots and hyphens, and start and end with a letter or number."
  }
}

variable "tags" {
  description = "Map of tags to apply to all supported resources."
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = "Whether to allow deletion of the bucket and all objects when running `terraform destroy`. Only enable for non-production environments."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Whether to enable S3 bucket versioning."
  type        = bool
  default     = true
}

variable "cors_rules" {
  description = <<-EOT
    List of CORS rules to apply to the bucket. Each rule supports:
    - `id`: rule identifier (optional)
    - `allowed_origins`: origins allowed to make cross-origin requests (use `["*"]` to allow all)
    - `allowed_methods`: HTTP methods allowed
    - `allowed_headers`: headers allowed in preflight requests
    - `expose_headers`: headers browsers are allowed to read
    - `max_age_seconds`: how long (seconds) browsers may cache the preflight response
  EOT
  type = list(object({
    id              = optional(string)
    allowed_origins = list(string)
    allowed_methods = list(string)
    allowed_headers = optional(list(string), ["*"])
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number, 3000)
  }))
  default = [{
    allowed_origins = ["*"]
    allowed_methods = ["GET", "HEAD"]
  }]

  validation {
    condition     = length(var.cors_rules) > 0 && alltrue([for r in var.cors_rules : length(r.allowed_origins) > 0 && length(r.allowed_methods) > 0])
    error_message = "At least one CORS rule is required, and every rule must define at least one allowed origin and one allowed method."
  }
}

variable "enable_static_website" {
  description = "Whether to configure the bucket as a static website (index/error documents)."
  type        = bool
  default     = true
}

variable "index_document" {
  description = "Object key that serves as the website index document."
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Object key that serves as the website error document. Set to null to disable."
  type        = string
  default     = null
}

variable "enable_public_read" {
  description = "Whether to attach a bucket policy granting public read access (`s3:GetObject`) to all objects. Required for a public CORS-enabled website; set to false to keep the bucket private."
  type        = bool
  default     = true
}

variable "additional_bucket_policy_statements" {
  description = "Additional IAM policy statements (in Terraform object form) to merge into the bucket policy."
  type        = list(any)
  default     = []
}

variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket."
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket. Must be false when `enable_public_read` is true."
  type        = bool
  default     = false
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket."
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket. Must be false when `enable_public_read` is true."
  type        = bool
  default     = false
}

variable "website_files_path" {
  description = "Path (relative to the caller's root module) of a directory whose contents are uploaded to the bucket. Set to null to skip uploads."
  type        = string
  default     = null
}
