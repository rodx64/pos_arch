variable "auth_db_endpoint" {
  type = string
}

variable "flag_db_endpoint" {
  type = string
}

variable "targeting_db_endpoint" {
  type = string
}

variable "auth_db_secret_arn" {
  type = string
}

variable "flag_db_secret_arn" {
  type = string
}

variable "targeting_db_secret_arn" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}

variable "sqs_queue_url" {
  type = string
}

variable "auth_master_key" {
  type      = string
  sensitive = true
}

variable "evaluation_api_key" {
  type      = string
  sensitive = true
}

variable "namespace" {
  type    = string
  default = "toggle-master"
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
}

variable "eks_tunnel_host" {
  type    = string
  default = ""
}

variable "redis_url" {
  type = string
}
