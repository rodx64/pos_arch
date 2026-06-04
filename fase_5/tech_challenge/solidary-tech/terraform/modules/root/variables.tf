### General
variable "env" {
  type = string
}


### VPC
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


### ECR
variable "ecr_repositories" {
  type    = list(string)
  default = []
}

variable "ecr_tag_prefixes" {
  type        = list(string)
  default     = []
  description = "Lista de prefixos de tag para a política de lifecycle do ECR"
}

variable "force_delete" {
  type = bool
}

variable "ami_id" {
  type = string
}


### EC2
variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}


### EKS
variable "enable_eks" {
  type    = bool
  default = false
}

variable "kubernetes_version" {
  type = string
}


### RDS
variable "databases" {
  type = map(object({
    db_name        = string
    db_user        = string
    app_owner_name = string
  }))
  default = {}
}


### DynamoDB
variable "dynamodb_tables" {
  type = map(object({
    table_name    = string
    hash_key      = string
    hash_key_type = optional(string, "S")
  }))
  default = {}
}


### SQS
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
