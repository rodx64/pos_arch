data "aws_secretsmanager_secret_version" "auth_db" {
  secret_id  = module.rds["auth-db"].rds_secret_arn
  depends_on = [module.rds]
}

data "aws_secretsmanager_secret_version" "flag_db" {
  secret_id  = module.rds["flag-db"].rds_secret_arn
  depends_on = [module.rds]
}

data "aws_secretsmanager_secret_version" "analytics_db" {
  secret_id  = module.rds["analytics-db"].rds_secret_arn
  depends_on = [module.rds]
}
