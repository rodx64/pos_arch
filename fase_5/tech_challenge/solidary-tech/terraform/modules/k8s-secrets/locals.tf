locals {
  donation_db_password = jsondecode(data.aws_secretsmanager_secret_version.donation_db.secret_string)["password"]
  ngo_db_password      = jsondecode(data.aws_secretsmanager_secret_version.ngo_db.secret_string)["password"]

  donation_db_password_encoded = urlencode(local.donation_db_password)
  ngo_db_password_encoded      = urlencode(local.ngo_db_password)
}
