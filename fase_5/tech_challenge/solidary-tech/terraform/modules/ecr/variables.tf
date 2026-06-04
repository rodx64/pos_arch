variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "repositories" {
  type        = list(string)
  description = "Lista de nomes dos repositórios ECR a criar"
}

variable "force_delete" {
  type    = bool
  default = false
}
