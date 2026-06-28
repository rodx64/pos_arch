output "monitoring_namespace" {
  description = "Namespace do monitoring criado no cluster"
  value       = kubernetes_namespace_v1.monitoring.metadata[0].name
}
