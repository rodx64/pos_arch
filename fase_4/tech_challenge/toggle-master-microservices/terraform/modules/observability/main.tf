locals {
  manifests_path = "${path.root}/../../../../eks/observability"
}

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
    for f in fileset("${local.manifests_path}/prometheus", "*.yaml") :
    f => f
  }

  manifest = yamldecode(templatefile(
    "${local.manifests_path}/prometheus/${each.value}",
    {
      prometheus_retention = var.prometheus_retention
      scrape_interval      = var.scrape_interval
    }
  ))

  depends_on = [kubernetes_namespace.monitoring]
}

resource "kubernetes_manifest" "service_monitors" {
  for_each = {
    for f in fileset("${local.manifests_path}/prometheus/service-monitors", "*.yaml") :
    f => f
  }

  manifest   = yamldecode(file("${local.manifests_path}/prometheus/service-monitors/${each.value}"))
  depends_on = [kubernetes_manifest.prometheus]
}

resource "kubernetes_manifest" "datadog" {
  for_each = {
    for f in fileset("${local.manifests_path}/datadog", "*.yaml") :
    f => f
  }

  manifest = yamldecode(templatefile(
    "${local.manifests_path}/datadog/${each.value}",
    {
      datadog_api_key = var.datadog_api_key
      datadog_site    = var.datadog_site
      environment     = var.environment
    }
  ))

  depends_on = [kubernetes_namespace.monitoring]
}
