data "aws_secretsmanager_secret_version" "donation_db" {
  secret_id = var.donation_db_secret_arn
}

data "aws_secretsmanager_secret_version" "ngo_db" {
  secret_id = var.ngo_db_secret_arn
}
