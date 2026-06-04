output "donation_db_url" {
  value     = "postgresql://postgres:${local.donation_db_password_encoded}@${var.donation_db_endpoint}/donation_db"
  sensitive = true
}

output "ngo_db_url" {
  value     = "postgresql://postgres:${local.ngo_db_password_encoded}@${var.ngo_db_endpoint}/ngo_db"
  sensitive = true
}
