variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "table_name" {
  type = string
}

variable "hash_key" {
  type    = string
  default = "id"
}

variable "hash_key_type" {
  type    = string
  default = "S"
}

variable "billing_mode" {
  type    = string
  default = "PAY_PER_REQUEST"
}
