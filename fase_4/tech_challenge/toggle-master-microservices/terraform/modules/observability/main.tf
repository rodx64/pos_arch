resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = {
      environment = var.environment
    }
  }
}

resource "kubernetes_manifest" "prometheus" {
  for_each = {
    for f in fileset("${var.manifests_path}/prometheus", "*.yaml") :
    f => f
  }

  manifest = yamldecode(templatefile(
    "${var.manifests_path}/prometheus/${each.value}",
    {
      prometheus_retention = var.prometheus_retention
      scrape_interval      = var.scrape_interval
      datadog_api_key      = var.datadog_api_key
    }
  ))

  depends_on = [kubernetes_namespace.monitoring]
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

resource "kubernetes_manifest" "datadog" {
  for_each = {
    for f in fileset("${var.manifests_path}/datadog", "*.yaml") :
    f => f
    if f != "secret.yaml"
  }

  manifest = yamldecode(templatefile(
    "${var.manifests_path}/datadog/${each.value}",
    {
      datadog_api_key = var.datadog_api_key
      environment     = var.environment
    }
  ))

  depends_on = [kubernetes_namespace.monitoring]
}
