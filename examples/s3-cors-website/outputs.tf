output "bucket_id" {
  description = "ID (name) of the S3 bucket."
  value       = module.s3_cors_website.bucket_id
}

output "website_endpoint" {
  description = "S3 static website endpoint."
  value       = module.s3_cors_website.website_endpoint
}

output "website_url" {
  description = "Full HTTPS URL of the website index document."
  value       = module.s3_cors_website.website_url
}

output "website_object_urls" {
  description = "Map of uploaded object keys to their HTTPS URLs."
  value       = module.s3_cors_website.website_object_urls
}
