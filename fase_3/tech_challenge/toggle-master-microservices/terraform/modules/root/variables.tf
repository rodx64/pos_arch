variable "env" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "azs" {
  type = list(string)
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "enable_eks" {
  type    = bool
  default = false
}

variable "kubernetes_version" {
  type    = string
}

variable "databases" {
  type = map(object({
    db_name        = string
    db_user        = string
    app_owner_name = string
  }))
  default = {}
}

variable "dynamodb_tables" {
  type = map(object({
    table_name    = string
    hash_key      = string
    hash_key_type = optional(string, "S")
  }))
  default = {}
}

variable "sqs_queues" {
  type = map(object({
    queue_name                 = string
    visibility_timeout_seconds = optional(number, 30)
    message_retention_seconds  = optional(number, 86400)
    create_dlq                 = optional(bool, true)
    max_receive_count          = optional(number, 3)
  }))
  default = {}
}

variable "redis_clusters" {
  type = map(object({
    cluster_id     = string
    node_type      = optional(string, "cache.t3.micro")
    engine_version = optional(string, "7.0")
  }))
  default = {}
}

variable "ecr_repositories" {
  type    = list(string)
  default = []
}

variable "force_delete" {
  type = bool
}

variable "auth_master_key" {
  type      = string
  sensitive = true
}

variable "evaluation_api_key" {
  type      = string
  sensitive = true
}
