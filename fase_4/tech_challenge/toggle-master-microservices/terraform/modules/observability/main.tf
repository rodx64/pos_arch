resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = {
      environment = var.environment
    }
  }
}

resource "kubernetes_secret_v1" "datadog" {
  metadata {
    name      = "datadog-secret"
    namespace = var.namespace
  }

  data = {
    api-key = var.datadog_api_key
  }

  depends_on = [kubernetes_namespace.monitoring]
}
