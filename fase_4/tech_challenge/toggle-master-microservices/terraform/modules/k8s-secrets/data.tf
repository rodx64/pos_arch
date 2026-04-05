data "aws_secretsmanager_secret_version" "auth_db" {
  secret_id = var.auth_db_secret_arn
}

data "aws_secretsmanager_secret_version" "flag_db" {
  secret_id = var.flag_db_secret_arn
}

data "aws_secretsmanager_secret_version" "analytics_db" {
  secret_id = var.analytics_db_secret_arn
}
