locals {
  auth_db_password      = jsondecode(data.aws_secretsmanager_secret_version.auth_db.secret_string)["password"]
  flag_db_password      = jsondecode(data.aws_secretsmanager_secret_version.flag_db.secret_string)["password"]
  analytics_db_password = jsondecode(data.aws_secretsmanager_secret_version.analytics_db.secret_string)["password"]

  # URL-encode caracteres especiais na senha
  auth_db_password_encoded      = urlencode(local.auth_db_password)
  flag_db_password_encoded      = urlencode(local.flag_db_password)
  analytics_db_password_encoded = urlencode(local.analytics_db_password)
}
