variable "environment" {
  type    = string
  default = "dev"
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
  default   = ""
}

variable "prometheus_retention" {
  type    = string
  default = "7d"
}

variable "scrape_interval" {
  type    = string
  default = "15s"
}
