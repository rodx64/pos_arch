# Aula 4 – Automação com IaC e CI/CD (Terraform + GitHub Actions)

Este projeto demonstra como integrar **Terraform** a pipelines de **CI/CD com GitHub Actions**.

## Estrutura
- `main.tf` → infraestrutura simples (VPC, Subnet, SG, EC2)
- `variables.tf` → variáveis parametrizáveis
- `outputs.tf` → outputs para auditoria
- `dev.tfvars` → configuração do ambiente de desenvolvimento
- `prod.tfvars` → configuração do ambiente de produção
- `.github/workflows/terraform.yml` → pipeline CI/CD (plan, validate, apply)
- `.github/workflows/rollback.yml` → pipeline de rollback baseado em tags

## Como usar

1. Inicialize o Terraform:
```bash
terraform init
```

2. Planeje e aplique em **dev**:
```bash
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

3. Planeje e aplique em **prod**:
```bash
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

## GitHub Actions
- Push na branch `develop` → aplica em dev
- Push na branch `main` → aplica em prod (com aprovação manual)
- Workflow `rollback.yml` → permite restaurar para uma versão anterior usando tags
