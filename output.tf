output "s3_object_url" {
  value = "https://${aws_s3_bucket.cors_bucket.bucket}.s3.amazonaws.com/${aws_s3_object.test_html.key}"
}
