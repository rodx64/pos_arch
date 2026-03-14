# Aula 2 – Projeto Terraform (Variáveis, Outputs e State)

Este projeto demonstra o uso de variáveis de diferentes tipos, outputs, state e backend remoto no Terraform.

## Estrutura de Arquivos

- `main.tf` → Define recursos AWS (VPC, Subnet e EC2).
- `variables.tf` → Declaração de variáveis (string, number, list, set, object).
- `outputs.tf` → Exposição de valores úteis (IP público, IDs de recursos).
- `backend.tf` → Configuração do backend remoto em S3 + DynamoDB para locking.
- `dev.tfvars` → Valores para ambiente de desenvolvimento.
- `prod.tfvars` → Valores para ambiente de produção.

## Pré-requisitos

- Conta AWS com permissões para criar VPC, Subnet e EC2.
- Terraform ou OpenTofu instalado.

## Passo a Passo

1. Inicializar o projeto:

```bash
terraform init
```

2. Validar configuração:

```bash
terraform validate
```

3. Visualizar plano para ambiente **dev**:

```bash
terraform plan -var-file="dev.tfvars"
```

4. Aplicar no ambiente **dev**:

```bash
terraform apply -var-file="dev.tfvars"
```

5. Aplicar no ambiente **prod**:

```bash
terraform apply -var-file="prod.tfvars"
```

6. Consultar outputs:

```bash
terraform output
```

7. Destruir a infraestrutura:

```bash
terraform destroy -var-file="dev.tfvars"
```

## Observações

- Ajuste os valores de `ami_id` de acordo com a região e sistema desejado.
- Substitua `meu-bucket-terraform-state` e `terraform-locks` no `backend.tf` pelos seus recursos AWS.
