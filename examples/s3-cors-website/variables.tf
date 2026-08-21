variable "region" {
  description = "AWS region in which to create the bucket."
  type        = string
  default     = "ap-south-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)."
  type        = string
}

variable "cors_allowed_origins" {
  description = "Origins allowed to make cross-origin requests to the bucket."
  type        = list(string)
  default     = ["*"]
}

variable "tags" {
  description = "Map of tags to apply to the bucket."
  type        = map(string)
  default     = {}
}
