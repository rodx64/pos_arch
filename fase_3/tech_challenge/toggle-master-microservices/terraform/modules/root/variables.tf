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
