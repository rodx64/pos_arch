output "website_endpoint" {
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
  description = "A URL final para acessar o frontend no navegador"
}
