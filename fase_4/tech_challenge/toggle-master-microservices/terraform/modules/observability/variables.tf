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
}

variable "datadog_app_key" {
  type      = string
  sensitive = true
}

variable "datadog_url" {
  type    = string
  default = "https://api.us5.datadoghq.com/"
}


variable "datadog_cluster_agent_token" {
  type      = string
  sensitive = true
}
