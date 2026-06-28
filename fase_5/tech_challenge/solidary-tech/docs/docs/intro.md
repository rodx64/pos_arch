# Propósito do Projeto: Solidary Tech

A **Solidary Tech** é uma plataforma focada em otimizar a conexão entre doadores, ONGs e voluntários. O projeto utiliza uma arquitetura Cloud-Native com foco em resiliência, governança de custos (FinOps) e observabilidade avançada.

Nossa missão é garantir que o máximo de recursos chegue às causas sociais, utilizando tecnologia de ponta para reduzir desperdícios operacionais.

Esta documentação cobre a entrega da **Fase 5** do Tech Challenge, organizada nas mesmas 5 frentes avaliadas:

| Frente | O que cobre | Onde ler |
|---|---|---|
| **0. Fundação DevOps** | Docker, Kubernetes (EKS), Terraform/Terragrunt, CI/CD, GitOps (ArgoCD), Observabilidade (Prometheus/Loki/OTel/Datadog) | [Arquitetura](./architecture.md), [Infraestrutura](./infra/terraform-terragrunt.md), [CI/CD](./infra/pipelines-cicd.md) |
| **1. SRE: Confiabilidade** | SLIs/SLOs do `donation-service`, dashboard de Error Budget, redução de MTTR | [SRE e Confiabilidade](./sre.md) |
| **2. FinOps** | Tagging obrigatório via Terraform, rightsizing por workload, forecast de custos | [FinOps](./finops.md) |
| **3. ITSM e AIOps** | Datadog Watchdog (detecção de anomalias) e fluxo de vida de incidentes | [AIOps e Gestão de Incidentes](./itsm-aiops.md) |
| **4. Multicloud, Segurança e DR** | Plano de Continuidade de Negócios, RTO/RPO e estratégia de backup/DR | *Em elaboração* |

## Visão rápida da arquitetura

Três microsserviços compõem o domínio de negócio — `donation-service` (Go), `ngo-service` e `volunteer-service` (Python/Flask) — rodando em EKS, com PostgreSQL (RDS) para dados transacionais, DynamoDB para voluntários e SQS para eventos de doação. Tudo provisionado via Terraform/Terragrunt, entregue via GitOps (ArgoCD) e observado via Prometheus + Loki + OpenTelemetry + Datadog. Detalhes completos em [Arquitetura](./architecture.md) e [Guia de APIs e Serviços](./how-to/apis-services.md).

## Onde encontrar os documentos-fonte completos

Esta documentação é um painel de navegação resumido. Os relatórios completos e detalhados (com tabelas de custo, queries PromQL, manifestos YAML, etc.) ficam versionados junto ao código no github do projeto, em [`Doc`][1]:

- `0_REQUISITOS.md` — checklist oficial dos requisitos do desafio
- `1_MELHORIAS.md` — changelog técnico de todas as melhorias implementadas
- `2_SRE_DOC.md` — SLIs/SLOs, dashboard e MTTR em detalhe
- `3_FORECAST.md` — forecast de custos completo, por ambiente
- `4_RIGHTSIZING.md` — análise completa de rightsizing e scaling (KEDA)
- `5_AIOPS_ITSM.md` — AIOps e fluxo de incidentes em detalhe

[1]: https://github.com/rodx64/pos_arch/tree/develop/fase_5/tech_challenge/doc
