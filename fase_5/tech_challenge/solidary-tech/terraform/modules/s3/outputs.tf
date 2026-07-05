output "bucket_name" {
  value = aws_s3_bucket.state.bucket
}

output "website_endpoint" {
  value       = aws_s3_bucket_website_configuration.app_website.website_endpoint
  description = "A URL final para acessar o frontend no navegador"
}
