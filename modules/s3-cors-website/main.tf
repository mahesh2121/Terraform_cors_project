# -----------------------------------------------------------------------------
# S3 bucket for static website hosting with CORS support
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "this" {
  bucket        = var.name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  count = var.versioning_enabled ? 1 : 0

  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# BucketOwnerEnforced disables ACLs; access is controlled via bucket policies.
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# -----------------------------------------------------------------------------
# CORS configuration
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_cors_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules

    content {
      id              = cors_rule.value.id
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

# -----------------------------------------------------------------------------
# Static website configuration
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_website_configuration" "this" {
  count = var.enable_static_website ? 1 : 0

  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = var.index_document
  }

  dynamic "error_document" {
    for_each = var.error_document != null ? [var.error_document] : []

    content {
      key = error_document.value
    }
  }
}

# -----------------------------------------------------------------------------
# Bucket policy (public read + optional additional statements)
# -----------------------------------------------------------------------------
locals {
  public_read_statement = {
    Sid       = "PublicReadGetObject"
    Effect    = "Allow"
    Principal = { AWS = "*" }
    Action    = "s3:GetObject"
    Resource  = "${aws_s3_bucket.this.arn}/*"
  }
}

resource "aws_s3_bucket_policy" "this" {
  count = var.enable_public_read ? 1 : 0

  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = concat([local.public_read_statement], var.additional_bucket_policy_statements)
  })
}

# -----------------------------------------------------------------------------
# Website content upload
# -----------------------------------------------------------------------------
locals {
  website_files_source_dir = var.website_files_path != null ? abspath("${path.root}/${var.website_files_path}") : null
  website_files            = local.website_files_source_dir != null ? fileset(local.website_files_source_dir, "**") : toset([])

  content_types = {
    ".css"   = "text/css"
    ".gif"   = "image/gif"
    ".htm"   = "text/html"
    ".html"  = "text/html"
    ".ico"   = "image/x-icon"
    ".jpeg"  = "image/jpeg"
    ".jpg"   = "image/jpeg"
    ".js"    = "application/javascript"
    ".json"  = "application/json"
    ".pdf"   = "application/pdf"
    ".png"   = "image/png"
    ".svg"   = "image/svg+xml"
    ".txt"   = "text/plain"
    ".webp"  = "image/webp"
    ".woff"  = "font/woff"
    ".woff2" = "font/woff2"
    ".xml"   = "application/xml"
  }
}

resource "aws_s3_object" "website_files" {
  for_each = local.website_files

  bucket       = aws_s3_bucket.this.id
  key          = each.value
  source       = "${local.website_files_source_dir}/${each.value}"
  etag         = filemd5("${local.website_files_source_dir}/${each.value}")
  content_type = lookup(local.content_types, try(regex("\\.[^.]+$", each.value), ""), "application/octet-stream")
}
