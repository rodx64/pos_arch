# Infraestrutura (Terraform / Terragrunt)

Toda a infraestrutura é provisionada via **Terraform**, orquestrada por **Terragrunt**. Nenhum recurso é criado manualmente no console AWS.

## Estrutura de módulos

```
terraform/
├── modules/
│   ├── vpc/            — VPC, subnets públicas/privadas, IGW, NAT Gateway
│   ├── eks/            — Cluster EKS + Node Groups (On-Demand e Spot)
│   ├── rds/            — PostgreSQL Multi-AZ (donation_db, ngo_db)
│   ├── dynamodb/       — Tabela volunteer-table (PAY_PER_REQUEST)
│   ├── sqs/            — Fila donation-queue + DLQ opcional
│   ├── ecr/            — Repositórios de imagem por serviço
│   ├── bastion/        — EC2 bastion para acesso ao cluster via SSH tunnel
│   ├── k8s-secrets/    — Secrets do Kubernetes (credenciais de banco, etc.)
│   ├── observability/  — SLOs, monitores e dashboards via provider Datadog
│   ├── velero/         — Bucket S3 cross-region para backup do cluster (us-west-2)
│   └── backup/         — Plano de backup AWS Backup para DynamoDB cross-region
└── environments/
    └── dev/            — Instanciação de todos os módulos para o ambiente DEV
```

## Módulos de Disaster Recovery

Dois módulos dedicados sustentam a estratégia de backup da plataforma (ver [Disaster Recovery e PCN](../disaster-recovery.md)):

**`modules/velero`** — Provisiona o bucket S3 `solidary-tech-velero-backups-{env}` na região de DR (`us-west-2`, via provider alias `aws.dr`), com versionamento habilitado e lifecycle de 90 dias. Referenciado pelo job `velero-infra` no pipeline, que executa **antes** da instalação do Velero no cluster.

**`modules/backup`** — Provisiona um `aws_backup_plan` com cópia cross-region da tabela DynamoDB `volunteer-table` para `us-west-2`, reaproveitando a mesma `LabRole` já usada pelo Velero (via `dependency` no Terragrunt).

## Tagging

Tags obrigatórias aplicadas a todos os recursos via `default_tags` no provider AWS:

```hcl
default_tags {
  tags = {
    Project     = "SolidaryTech"
    Environment = title(var.environment)
    CostCenter  = "NGO-Core"
    ManagedBy   = "Terraform"
  }
}
```

> Recursos via `aws_autoscaling_group` exigem declaração explícita de tags — não herdam `default_tags` automaticamente.

## Validação local sem estado remoto

O Terragrunt usa `mock_outputs` para permitir `plan`/`validate` sem depender do estado remoto real do EKS — fundamental para rodar a esteira em PRs sem cluster provisionado:

```hcl
mock_outputs_allowed_terraform_commands = ["validate", "plan"]
mock_outputs = {
  eks_cluster_endpoint = "https://mock"
  eks_cluster_ca       = "bW9jaw=="
  dynamodb_table_arns  = { "volunteer-table" = "arn:aws:dynamodb:us-east-1:000000000000:table/mock" }
}
```

## Links do repositório

- [Módulos Terraform][tf-modules]
- [Ambiente DEV (Terragrunt)][tg-dev]
- [Módulo Velero][tf-velero]
- [Módulo AWS Backup][tf-awsbackup]

[tf-modules]: https://github.com/rodx64/pos_arch/tree/develop/fase_5/tech_challenge/solidary-tech/terraform/modules
[tg-dev]: https://github.com/rodx64/pos_arch/tree/develop/fase_5/tech_challenge/solidary-tech/terraform/environments/dev/
[tf-velero]: https://github.com/rodx64/pos_arch/tree/develop/fase_5/tech_challenge/solidary-tech/terraform/modules/velero
[tf-awsbackup]: https://github.com/rodx64/pos_arch/tree/develop/fase_5/tech_challenge/solidary-tech/terraform/modules/backup
