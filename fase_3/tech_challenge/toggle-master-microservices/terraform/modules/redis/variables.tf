variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "node_type" {
  type    = string
  default = "cache.t3.micro"
}

variable "engine_version" {
  type    = string
  default = "7.0"
}

variable "port" {
  type    = number
  default = 6379
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}
