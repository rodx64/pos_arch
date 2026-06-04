variable "donation_db_endpoint" {
  type = string
}

variable "ngo_db_endpoint" {
  type = string
}


variable "donation_db_secret_arn" {
  type = string
}

variable "ngo_db_secret_arn" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}

variable "sqs_queue_url" {
  type = string
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
