include "root" {
  path = "${get_repo_root()}/fase_5/tech_challenge/solidary-tech/terraform/root.hcl"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "solidary-iac-state"
    key            = "dynamodb-backup/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
}

terraform {
  source = "${get_repo_root()}/fase_5/tech_challenge/solidary-tech/terraform/modules/backup"
}

dependency "infra" {
  config_path  = "${get_repo_root()}/fase_5/tech_challenge/solidary-tech/terraform/environments/dev/"
  skip_outputs = false

  # mock - "somente para os comandos validate e plan. Se o output real não estiver disponível, use os valores fictícios abaixo em vez de falhar."
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    dynamodb_table_arns = { "volunteer-table" = "arn:aws:dynamodb:us-east-1:000000000000:table/mock" }
  }
}

dependency "velero" {
  config_path  = "${get_repo_root()}/fase_5/tech_challenge/solidary-tech/velero/dev/"
  skip_outputs = false

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    velero_role_arn = "arn:aws:iam::000000000000:role/LabRole"
  }
}

inputs = {
  environment         = "dev"
  dynamodb_table_arn  = dependency.infra.outputs.dynamodb_table_arns["volunteer-table"]
  backup_role_arn     = dependency.velero.outputs.velero_role_arn
}
