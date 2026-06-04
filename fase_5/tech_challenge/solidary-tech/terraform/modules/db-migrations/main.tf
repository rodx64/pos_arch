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
}

resource "kubernetes_job_v1" "flyway_migration" {
  for_each = local.services

  metadata {
    name      = "${each.key}-db-migration"
    namespace = var.namespace
    labels = {
      app = "${each.key}-migration"
    }
  }

  spec {
    template {
      metadata {
        labels = {
          app = "${each.key}-migration"
        }
      }
      spec {
        container {
          name  = "flyway"
          image = each.value.image

          env {
            name  = "FLYWAY_URL"
            value = replace(each.value.db_url, "postgresql://", "jdbc:postgresql://")
          }

          args = ["migrate", "-connectRetries=60"]
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
  }

  wait_for_completion = false
}
