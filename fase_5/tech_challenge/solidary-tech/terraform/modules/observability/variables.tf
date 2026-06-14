variable "env" {
  description = "Ambiente de deploy (ex: dev, prod)"
  type        = string
  default     = "dev"
}

variable "namespace" {
  type = string
}

variable "eks_cluster_endpoint" {
  type = string
}

variable "eks_cluster_ca" {
  type = string
}

variable "eks_cluster_token" {
  type      = string
  sensitive = true
  default   = ""
}

variable "eks_tunnel_host" {
  type    = string
  default = ""
}

variable "datadog_api_key" {
  type      = string
  sensitive = true
}

variable "datadog_app_key" {
  type      = string
  sensitive = true
}

variable "datadog_url" {
  type    = string
  default = "https://api.datadoghq.com/"
}

variable "datadog_cluster_agent_token" {
  type      = string
  sensitive = true
}

variable "slo_services" {
  description = "Mapa de serviços e seus limiares de SLO para os monitores"
  type = map(object({
    slo_target         = number
    latency_percentile = number # (ex: 90, 95, 99)
    latency_threshold  = number # Limiar em segundos (ex: 0.25)
  }))
  default = {}
}
