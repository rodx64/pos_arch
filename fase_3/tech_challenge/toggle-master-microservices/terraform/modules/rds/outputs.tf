output "rds_endpoint" {
  value = module.db.db_instance_endpoint
}

output "rds_secret_arn" {
  value = module.db.db_instance_master_user_secret_arn
}
