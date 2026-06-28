variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

variable "versioning_configuration" {
  type        = string
  default     = "Enabled"
  description = "Configuração de versionamento do Bucket. (Enabled, Disabled)"
}
