variable "environment" {
  type = string
}

variable "dr_region" {
  type        = string
  description = "Região secundária (DR) onde o bucket de backup do Velero é criado — diferente da região primária da infra"
  default     = "us-west-2"
}
