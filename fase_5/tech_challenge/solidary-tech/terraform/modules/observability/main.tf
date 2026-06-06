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
    app-key = var.datadog_app_key
    token   = var.datadog_cluster_agent_token
  }

  depends_on = [kubernetes_namespace.monitoring]
}

resource "kubectl_manifest" "datadog_manifests" {
  for_each = fileset("${path.module}/../../../eks/observability/datadog", "*.yaml")

  yaml_body = templatefile("${path.module}/../../../eks/observability/datadog/${each.value}", {
    cluster_agent_token = var.datadog_cluster_agent_token
    api_key             = var.datadog_api_key
    app_key             = var.datadog_app_key
  })
}
