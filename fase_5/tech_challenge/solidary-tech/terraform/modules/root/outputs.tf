### VPC Outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}


### S3 Outputs
output "s3_bucket" {
  value = module.s3.bucket_name
}


### RDS Outputs
output "rds_endpoints" {
  value = { for k, v in module.rds : k => v.rds_endpoint }
}

output "rds_secret_arns" {
  value     = { for k, v in module.rds : k => v.rds_secret_arn }
  sensitive = true
}


### DynamoDB Outputs
output "dynamodb_table_names" {
  value = { for k, v in module.dynamodb : k => v.table_name }
}

output "dynamodb_table_arns" {
  value = { for k, v in module.dynamodb : k => v.table_arn }
}


### SQS Outputs
output "sqs_queue_urls" {
  value = { for k, v in module.sqs : k => v.queue_url }
}

output "sqs_queue_arns" {
  value = { for k, v in module.sqs : k => v.queue_arn }
}


### EC2 Outputs
output "ec2_instance_id" {
  value = module.ec2.instance_id
}


### EKS Outputs
output "eks_cluster_name" {
  value       = try(module.eks[0].cluster_name, null)
  description = "Nome do cluster EKS quando habilitado"
}

output "eks_cluster_endpoint" {
  value = try(data.aws_eks_cluster.this[0].endpoint, "")
}

output "eks_cluster_ca" {
  value = try(data.aws_eks_cluster.this[0].certificate_authority[0].data, "")
}

output "eks_cluster_token" {
  value     = try(data.aws_eks_cluster_auth.this[0].token, "")
  sensitive = true
}
