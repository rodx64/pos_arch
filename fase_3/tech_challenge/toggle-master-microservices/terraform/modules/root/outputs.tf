output "vpc_id" { 
  value = module.vpc.vpc_id 
}

output "s3_bucket" { 
  value = module.s3.bucket_name 
}

output "ec2_instance_id" { 
  value = module.ec2.instance_id 
}

output "eks_cluster_name" {
  value       = try(module.eks[0].cluster_name, null)
  description = "Nome do cluster EKS quando habilitado"
}

output "rds_endpoints" {
  value = { for k, v in module.rds : k => v.rds_endpoint }
}

output "rds_secret_arns" {
  value     = { for k, v in module.rds : k => v.rds_secret_arn }
  sensitive = true
}

output "dynamodb_table_names" {
  value = { for k, v in module.dynamodb : k => v.table_name }
}

output "dynamodb_table_arns" {
  value = { for k, v in module.dynamodb : k => v.table_arn }
}

output "sqs_queue_urls" {
  value = { for k, v in module.sqs : k => v.queue_url }
}

output "sqs_queue_arns" {
  value = { for k, v in module.sqs : k => v.queue_arn }
}
