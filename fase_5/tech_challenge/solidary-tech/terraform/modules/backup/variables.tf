variable "environment" {
  type = string
}

variable "dynamodb_table_arn" {
  type        = string
  description = "ARN da tabela DynamoDB a proteger (ex: output do módulo terraform/modules/dynamodb para a volunteer-table)"
}

variable "backup_role_arn" {
  type        = string
  description = "ARN da role IAM usada pelo AWS Backup para realizar o backup/cópia (no ambiente de laboratório, a LabRole — mesmo padrão do Velero, ver terraform/modules/velero/main.tf)"
}

variable "retention_days" {
  type        = number
  description = "Retenção, em dias, do backup no vault primário e na cópia DR. Mantido igual ao lifecycle do bucket do Velero (90 dias) para consistência de governança entre os dois mecanismos de backup."
  default     = 90
}
