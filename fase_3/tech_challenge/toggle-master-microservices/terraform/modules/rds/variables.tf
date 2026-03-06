variable "allocated_storage" {
  type    = number
  default = 20
}

variable "app_owner_name" {
  type = string
}

variable "env" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_name" {
  type = string
}

variable "engine" {
  type    = string
  default = "postgres"
}

variable "engine_version" {
  type    = string
  default = "13.23"
}

variable "family" {
  type    = string
  default = "postgres13"
}

variable "identifier" {
  type    = string
  default = "demodb"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "port" {
  type    = number
  default = 5432
}

variable "project_name" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type = string
}

variable "vpc_id" {
  type = string
}
