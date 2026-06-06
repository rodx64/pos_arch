output "monitoring_namespace" {
  description = "Namespace do monitoring criado no cluster"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}
