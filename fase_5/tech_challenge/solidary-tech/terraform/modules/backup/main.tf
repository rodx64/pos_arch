resource "aws_backup_vault" "primary" {
  name = "solidary-tech-dynamodb-backup-${var.environment}"
}

resource "aws_backup_vault" "dr" {
  provider = aws.dr
  name     = "solidary-tech-dynamodb-backup-dr-${var.environment}"
}

resource "aws_backup_plan" "dynamodb_cross_region" {
  name = "solidary-tech-dynamodb-plan-${var.environment}"

  rule {
    rule_name         = "daily-cross-region"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = "cron(0 3 * * ? *)"

    lifecycle {
      delete_after = var.retention_days
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.dr.arn

      lifecycle {
        delete_after = var.retention_days
      }
    }
  }
}

resource "aws_backup_selection" "volunteer_table" {
  name         = "volunteer-table-selection"
  plan_id      = aws_backup_plan.dynamodb_cross_region.id
  iam_role_arn = var.backup_role_arn

  resources = [
    var.dynamodb_table_arn,
  ]
}
