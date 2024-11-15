# Remote backend configuration
terraform {
  backend "s3" {
    bucket  = "my-terraform-state-bucket12121"    # Replace with your S3 bucket name
    key     = "terraform/state/terraform.tfstate" # Path to the state file in the bucket
    region  = "ap-south-1"                        # The AWS region where the bucket is located
    encrypt = true                                # Enable encryption for the state file in S3

    # Optionally, configure a DynamoDB table for state locking (recommended for collaboration)
    dynamodb_table = "terraform-lock-table"      # DynamoDB table name for state locking
    acl            = "bucket-owner-full-control" # Permissions for the state file
  }
}

# AWS Provider Configuration
provider "aws" {
  region = "ap-south-1"
}

# Your existing resources (no changes here)
resource "aws_s3_bucket" "cors_bucket" {
  bucket = "my-cors-enabled-bucket-12345" # Change to a globally unique bucket name
}

resource "aws_s3_bucket_acl" "cors_bucket_acl" {
  bucket = aws_s3_bucket.cors_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_public_access_block" "cors_bucket_public_access_block" {
  bucket = aws_s3_bucket.cors_bucket.bucket

  block_public_acls   = true
  ignore_public_acls  = false
  block_public_policy = false
}

resource "aws_s3_bucket_cors_configuration" "cors_config" {
  bucket = aws_s3_bucket.cors_bucket.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_object" "test_html" {
  bucket = aws_s3_bucket.cors_bucket.bucket
  key    = "index.html"
  source = "index.html"
  acl    = "public-read"
}

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
