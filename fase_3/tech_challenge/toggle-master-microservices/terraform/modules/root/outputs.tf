output "vpc_id" { 
  value = module.vpc.vpc_id 
}

output "s3_bucket" { 
  value = module.s3.bucket_name 
}

output "ec2_instance_id" { 
  value = module.ec2.instance_id 
}

output "rds_endpoint" { 
  value = module.rds.rds_endpoint 
}

output "eks_cluster_name" {
  value       = try(module.eks[0].cluster_name, null)
  description = "Nome do cluster EKS quando habilitado"
}
