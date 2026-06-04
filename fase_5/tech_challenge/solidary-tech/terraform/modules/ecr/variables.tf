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

variable "tag_prefixes" {
  type        = list(string)
  description = "Lista de prefixos de tag usados pelo lifecycle policy"
  default     = []
}

variable "force_delete" {
  type    = bool
  default = false
}
