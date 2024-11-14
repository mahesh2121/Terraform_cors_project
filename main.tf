provider "aws" {
  region = "us-east-1"
}

# Create an S3 bucket
resource "aws_s3_bucket" "cors_bucket" {
  bucket = "my-cors-enabled-bucket-12345" # Change to a globally unique bucket name
  acl    = "public-read"  # Set to private, we'll manage public access via policy
}

# Remove public access block settings (allow public access if needed)
resource "aws_s3_bucket_public_access_block" "cors_bucket_public_access_block" {
  bucket = aws_s3_bucket.cors_bucket.bucket

  block_public_acls   = true  # Allow public ACLs
  ignore_public_acls  = false  # Don't ignore ACLs
  block_public_policy = false  # Allow public policies
}

# Configure CORS using aws_s3_bucket_cors_configuration
resource "aws_s3_bucket_cors_configuration" "cors_config" {
  bucket = aws_s3_bucket.cors_bucket.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

# Upload an example HTML file to the S3 bucket to test CORS (using aws_s3_object instead)
resource "aws_s3_object" "test_html" {
  bucket = aws_s3_bucket.cors_bucket.bucket
  key    = "index.html"
  source = "index.html"
  acl    = "public-read"  # This is okay for public access testing
}

# Define a policy to allow public read access to all objects in the bucket
resource "aws_s3_bucket_policy" "cors_bucket_policy" {
  bucket = aws_s3_bucket.cors_bucket.bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.cors_bucket.bucket}/*"
        Principal = "*"
      },
    ]
  })
}

# Output the URL of the uploaded object
