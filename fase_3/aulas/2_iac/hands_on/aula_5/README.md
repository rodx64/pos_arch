# Aula 5 – Terragrunt (Multi-ambiente) com EKS real

Projeto didático e **funcional** que cria:
- VPC com subnets públicas;
- EKS **real** (cluster + node group gerenciado);
- Orquestração via **Terragrunt** com ambientes **dev** e **prod**;
- Remote state centralizado (S3 + DynamoDB) com **bootstrap**.

> Observação: subnets públicas são usadas por simplicidade didática. Em produção, prefira **subnets privadas** com NAT.

## Pré-requisitos
- AWS credencial válida (perfil/variáveis);
- Terraform ou OpenTofu;
- Terragrunt.

## Passos resumidos
1) Faça o **bootstrap** do state (S3/DynamoDB) em `bootstrap/`.
2) Atualize `live/terragrunt.hcl` com os nomes retornados.
3) Aplique **dev** e **prod** com `terragrunt run-all`.

Consulte também os READMEs dos módulos em `modules/vpc` e `modules/eks`.
