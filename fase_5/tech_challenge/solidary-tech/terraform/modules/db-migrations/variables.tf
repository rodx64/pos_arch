variable "namespace" {
  type        = string
  description = "Namespace onde o Job de migração será executado"
  default     = "solidary-tech"
}

variable "donation_db_url" {
  type        = string
  description = "URL de conexão do banco de doações (Postgres)"
  sensitive   = true
}

variable "ngo_db_url" {
  type        = string
  description = "URL de conexão do banco de ONGs (Postgres)"
  sensitive   = true
}

variable "donation_migration_image" {
  type        = string
  description = "Imagem ECR contendo o Flyway e as migrations de donation"
}

variable "ngo_migration_image" {
  type        = string
  description = "Imagem ECR contendo o Flyway e as migrations de NGO"
}

variable "eks_cluster_endpoint" {
  type        = string
  description = "Endpoint do cluster EKS"
}

variable "eks_cluster_ca" {
  type        = string
  description = "Certificate Authority do cluster EKS"
}

variable "eks_cluster_token" {
  type        = string
  description = "Token de autenticação do EKS"
  sensitive   = true
}

variable "eks_tunnel_host" {
  type        = string
  description = "Host para túnel local (ex: localhost:6443), se aplicável"
  default     = ""
}
