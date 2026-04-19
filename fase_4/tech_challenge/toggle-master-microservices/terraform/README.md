# iac-final-project – Aula 8 (Terraform + Terragrunt + AWS)

Projeto final do curso, com infraestrutura completa, modular e automatizada.
Região padrão: **us-east-1**.

## Componentes
- **modules/**: VPC, EC2, RDS, S3 e EKS (opcional)
- **modules/root/**: módulo agregador que compõe toda a infra
- **backend/**: S3 (state) + DynamoDB (lock)
- **environments/**: dev, staging, prod (Terragrunt)
- **.github/workflows/**: pipeline com *plan* + aprovação manual

## Passo a passo
1. **Backend**
   ```bash
   cd backend
   terraform init
   terraform apply
   ```
2. **Execução com Terragrunt**
   ```bash
   cd environments/dev
   terragrunt init
   terragrunt plan
   # terragrunt apply   # manualmente ou via aprovação no pipeline
   ```
3. **EKS opcional**
   - Habilitado por padrão no `prod` via `enable_eks = true`.
   - Pode habilitar no `dev/staging` ajustando `inputs` em `terragrunt.hcl`.

## CI/CD (GitHub Actions + OIDC)
- Atualize `<ACCOUNT_ID>` com sua conta AWS no workflow.
- Crie o OIDC provider `token.actions.githubusercontent.com` e a role `github-actions-terraform`.
- O pipeline executa **plan** e espera **aprovação manual** antes do **apply**.

## Segurança
- Evite credenciais estáticas. Use OIDC.
- Ajuste CIDRs/portas conforme sua política interna.
- Em produção, use Secrets Manager para credenciais de DB.
