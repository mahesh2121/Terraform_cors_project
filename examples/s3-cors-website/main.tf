terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.67, < 6.63"
    }
  }

  # Remote state in S3 (partial configuration).
  # Initialize with: terraform init -backend-config=backend.s3.hcl
  # See backend.s3.hcl.example.
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

module "s3_cors_website" {
  source = "../../modules/s3-cors-website"

  name               = var.bucket_name
  website_files_path = "www"
  tags               = var.tags

  cors_rules = [
    {
      id              = "allow-get-from-anywhere"
      allowed_origins = var.cors_allowed_origins
      allowed_methods = ["GET", "HEAD"]
      allowed_headers = ["*"]
      max_age_seconds = 3000
    }
  ]
}
