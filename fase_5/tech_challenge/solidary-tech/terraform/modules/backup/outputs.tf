output "backup_plan_id" {
  value       = aws_backup_plan.dynamodb_cross_region.id
  description = "ID do plano de backup do DynamoDB, para referência em monitoramento/alertas (ex: AWS Cost Anomaly Detection, ver doc 3_FINOPS — Seção 3)"
}

output "dr_vault_arn" {
  value       = aws_backup_vault.dr.arn
  description = "ARN do vault de destino na região de DR, para validação manual via AWS CLI/Console durante o runbook de recuperação (PCN, Seção 4.3)"
}
