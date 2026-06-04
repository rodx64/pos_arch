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
            name = "FLYWAY_URL"
            # [2] = Host, [3] = Porta, [4] = Banco de Dados
            value = "jdbc:postgresql://${local.parsed_urls[each.key][2]}:${local.parsed_urls[each.key][3]}/${local.parsed_urls[each.key][4]}"
          }
          env {
            name = "FLYWAY_USER"
            # [0] = Usuário (com urldecode para remover caracteres especiais como %21)
            value = urldecode(local.parsed_urls[each.key][0])
          }
          env {
            name = "FLYWAY_PASSWORD"
            # [1] = Senha (descodificada)
            value = urldecode(local.parsed_urls[each.key][1])
          }
          env {
            name  = "FLYWAY_LOCATIONS"
            value = "filesystem:/flyway/sql"
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
