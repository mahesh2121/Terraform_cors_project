output "bucket_id" {
  description = "ID (name) of the S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Bucket domain name, e.g. `<name>.s3.amazonaws.com`."
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional bucket domain name, e.g. `<name>.s3.<region>.amazonaws.com`."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "website_endpoint" {
  description = "S3 static website endpoint (only when `enable_static_website` is true)."
  value       = var.enable_static_website ? aws_s3_bucket_website_configuration.this[0].website_endpoint : null
}

output "website_url" {
  description = "Full HTTPS URL of the website index document (only when `enable_static_website` is true)."
  value       = var.enable_static_website ? "https://${aws_s3_bucket_website_configuration.this[0].website_endpoint}/${var.index_document}" : null
}

output "website_object_urls" {
  description = "Map of uploaded object keys to their HTTPS URLs."
  value       = {
    for key, object in aws_s3_object.website_files :
    key => "https://${aws_s3_bucket.this.bucket_regional_domain_name}/${object.key}"
  }
}

output "cors_configuration_id" {
  description = "ID of the S3 bucket CORS configuration."
  value       = aws_s3_bucket_cors_configuration.this.id
}

output "bucket_policy_id" {
  description = "ID of the bucket policy (only when `enable_public_read` is true)."
  value       = var.enable_public_read ? aws_s3_bucket_policy.this[0].id : null
}
