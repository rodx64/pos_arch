locals {
  services = {
    donation = {
      db_url      = var.donation_db_url
      image       = var.donation_migration_image
      secret_name = "donation-db-creds"
    }
    ngo = {
      db_url      = var.ngo_db_url
      image       = var.ngo_migration_image
      secret_name = "ngo-db-creds"
    }
  }
  parsed_urls = {
    for k, v in local.services : k => regex("^postgres(?:ql)?://([^:]+):([^@]+)@([^:]+):(\\d+)/(.+)$", v.db_url)
  }
}
