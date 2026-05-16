# Tech Challenge - Fase 4

[Projeto](../toggle-master-microservices/) que engloba os conhecimentos obtidos em todas as disciplinas da fase 4, focando em Infraestrutura como Código (IaC), Kubernetes, GitOps e, primordialmente, uma stack avançada de Observabilidade e Resiliência.

---

## 📖 Visão Geral e Contexto

Este projeto representa uma arquitetura de microserviços moderna e resiliente, operando em ambiente de nuvem (**AWS EKS**). O objetivo central foi sair do monitoramento básico e implementar um ecossistema de **Observabilidade 360°** capaz de auto-remediação.

A stack é baseada no **Toggle Master**, um sistema de gerenciamento de Feature Flags distribuído, onde a performance e a disponibilidade são críticas.

### 🏗️ Arquitetura de Infraestrutura
A infraestrutura é totalmente provisionada via **Terraform**, seguindo uma abordagem modular para garantir escalabilidade e reutilização. Utilizamos o **Amazon EKS** como orquestrador, com suporte de serviços gerenciados como **RDS (PostgreSQL)**, **DynamoDB**, **Redis** e **SQS** para garantir persistência e mensageria robustas.

### 🔭 O Ecossistema de Observabilidade (OTel + APM)
O diferencial desta fase é a implementação do **OpenTelemetry (OTel) Collector**. Ele atua como um hub centralizado de telemetria que recebe, processa e exporta dados (Métricas, Logs e Traces) para múltiplos destinos:

* **Métricas:** Coletadas pelo **Prometheus** e visualizadas em Dashboards customizados no **Grafana**.
* **Logs:** Agregados pelo **Loki** através do roteamento do OTel, permitindo buscas granulares integradas ao contexto das métricas.
* **APM & Distributed Tracing:** Exportados para o **Datadog**, permitindo uma visão detalhada do *Service Map* e rastreamento de requisições (*Traces*), facilitando a identificação de gargalos de latência.


### 🤖 Resiliência e Self-Healing
O projeto implementa um ciclo completo de resposta a incidentes:
1.  **Detecção:** Monitores no Datadog e alertas no Prometheus identificam anomalias (ex: picos de erro 5xx ou consumo de CPU).
2.  **Notificação:** Foi utilizada integração com **PagerDuty** e **Discord** para alerta imediato ao time de engenharia.
3.  **Remediação (Self-Healing):** Automações que detectam falhas críticas e executam ações corretivas automáticas, como o restart de Pods degradados ou escalonamento reativo, garantindo o retorno ao estado saudável sem intervenção manual.

---

## 🛠️ Components
- **Backend (Terraform state)**: [path](../toggle-master-microservices/terraform/backend/)
- **Modules**: [dynamodb](../toggle-master-microservices/terraform/modules/dynamodb/), [ec2](../toggle-master-microservices/terraform/modules/ec2/), [ecr](../toggle-master-microservices/terraform/modules/ecr/), [eks](../toggle-master-microservices/terraform/modules/eks/), [k8s-secrets](../toggle-master-microservices/terraform/modules/k8s-secrets/), [rds](../toggle-master-microservices/terraform/modules/rds/), [redis](../toggle-master-microservices/terraform/modules/redis/), [root](../toggle-master-microservices/terraform/modules/root/), [s3](../toggle-master-microservices/terraform/modules/s3/), [sqs](../toggle-master-microservices/terraform/modules/sqs/), [vpc](../toggle-master-microservices/terraform/modules/vpc/), [observability](../toggle-master-microservices/terraform/modules/observability/)
- **Kubernetes**: [manifestos](../toggle-master-microservices/eks) (gerenciados via **ArgoCD**)
- **Services** [analytics-service](../toggle-master-microservices/services/analytics-service/), [auth-service](../toggle-master-microservices/services/auth-service/), [evaluation-service](../toggle-master-microservices/services/evaluation-service/), [flag-service](../toggle-master-microservices/services/flag-service/), [targeting-service](../toggle-master-microservices/services/targeting-service/)
- **Workflows**: [ci-analytics](../../../.github/workflows/ci-analytics.yml), [ci-auth](../../../.github/workflows/ci-auth.yml), [ci-evaluation](../../../.github/workflows/ci-evaluation.yml)
, [ci-flag](../../../.github/workflows/ci-flag.yml), [ci-targeting](../../../.github/workflows/ci-targeting.yml), [self-healing](../../../.github/workflows/self-healing.yml)

---

## 🚀 CI/CD & GitOps



### 1. Infraestrutura (IaC)
Qualquer alteração no diretório `terraform/` dispara o workflow de validação e plano. O deploy é controlado para garantir que a fundação do cluster EKS esteja sempre íntegra.

### 2. Ciclo de Vida dos Serviços
Os serviços possuem pipelines independentes que realizam o build, scan de vulnerabilidades, push para o **ECR** e a atualização dos manifestos. 
- **Analytics, Auth, Evaluation, Flag, Targeting.**

O **ArgoCD** monitora o diretório `eks/` e garante que o estado real do cluster seja idêntico ao definido no repositório (GitOps), facilitando rollbacks e auditoria.
