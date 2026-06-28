# Melhorias implementadas no Tech Challenge

Este documento lista as melhorias aplicadas no challenge do `tech_challenge`, cobrindo todos os serviços e aplicações do projeto, incluindo infra local e ajustes de código.

## 1. Suporte a LocalStack para testes locais

- Adicionado suporte ao LocalStack OSS para permitir testes AWS locais sem depender de contas pagas.
- Configurado `SERVICES=sqs,dynamodb` no `docker-compose.yml` para ativar apenas os serviços usados pelo projeto.
- Definido as credenciais padrão `AWS_ACCESS_KEY_ID=test`, `AWS_SECRET_ACCESS_KEY=test` e `AWS_DEFAULT_REGION=us-east-1` para acessibilidade local.
- Criado `init-aws.sh` como hook de startup do LocalStack para provisionar recursos necessários automaticamente.
- Tornada a inicialização do LocalStack idempotente para reinícios seguros:
  - fila SQS: `donation-queue`
  - tabela DynamoDB: `volunteer-table`

## 2. Melhoria de infraestrutura local e orquestração

- Ajustado `docker-compose.yml` para expor o PostgreSQL em `5432:5432`, permitindo conexão por DBeaver e outras ferramentas externas.
- Organizado `depends_on` para que `postgres` e `localstack` fiquem prontos antes dos serviços que dependem deles.
- Instruções de healthcheck garantem que os serviços só iniciem após os componentes críticos estarem saudáveis.

## 3. Qualidade do banco de dados e scripts de inicialização

- Corrigido `init-postgres.sh` para criar o banco e a estrutura de tabelas corretamente no PostgreSQL sem erro de sintaxe.
- Melhorado o fluxo de bootstrap do banco para não interromper a inicialização do container.
- Preservado os dados do PostgreSQL em volume nomeado para facilitar testes locais persistentes.

## 4. Robustez dos serviços Python

- Atualizados os serviços Python (`ngo-service` e `volunteer-service`) para instalar `setuptools` e `wheel`, evitando falhas de importação em Alpine.
- Garantido que `gunicorn` inicialize corretamente mesmo quando `pkg_resources` é usado por dependências.
- Implementado comportamento de espera e criação automática de recursos no `volunteer-service`.

## 5. Resiliência do `volunteer-service`

- Adicionada função genérica `wait_for_service(...)` para aguardar disponibilidade de AWS/LocalStack antes de prosseguir.
- Implementado `ensure_dynamodb_table(...)` para verificar e criar `volunteer-table` automaticamente, evitando erros de tabela inexistente.
- Isso torna o serviço robusto tanto em ambiente local quanto em AWS real.

## 6. Versionamento de Banco de Dados com Flyway

- Adotado o **Flyway** para gerenciamento e versionamento profissional de schemas nos bancos de dados relacionais (`donation-service` e `ngo-service`).
- Separação de responsabilidades: as aplicações não criam mais as próprias tabelas em tempo de execução, delegando a função para scripts versionados (ex: `V1__initial_schema.sql`).
- Implementação de imagens Docker exclusivas (`Dockerfile.migration`) baseadas no Flyway, mantendo os containers das aplicações enxutos e focados na regra de negócio.
- Criação de um módulo exclusivo no **Terraform** (`db-migrations`) orquestrado via **Terragrunt**, disparando *Kubernetes Jobs* que garantem a criação/atualização das tabelas antes que as aplicações subam no EKS.
- Adaptação dos pipelines de CI/CD (GitHub Actions) para realizar o build e push simultâneo da aplicação e da migração, com atualização automática das tags no repositório de infraestrutura.

## 7. Endpoint sintético `/cpu` nos 3 serviços

- O `k6-load-test.yaml` já fazia requisições para `/cpu` nos 3 serviços, mas a rota não existia em nenhum dos `main.go`/`app.py`.
- Implementada a rota `/cpu` em `donation-service` (Go), `ngo-service` e `volunteer-service` (Flask): endpoint sintético de estresse de CPU, sem efeito sobre banco de dados ou fila, aceitando `?duration_ms=N` (padrão 50ms, máximo 500ms) para controlar a intensidade da carga.
- Objetivo: gerar um sinal real de CPU para calibrar thresholds de HPA/KEDA e validar o rightsizing com dados de carga reproduzíveis, em vez de estimativa pura.

## 8. Scaling baseado em tráfego com KEDA (`donation-service`)

- Avaliada a viabilidade de scaling baseado em fila (SQS): descartada por ora, já que a `donation-queue` hoje só tem produtor (`donation-service`) — não há consumidor no código, logo não há profundidade de fila com relação causal para escalar contra.
- Para o `donation-service`, substituído o HPA anterior por **KEDA**, escalando por **tráfego HTTP** (`sum(rate(http_requests_total{service="donation"}[2m]))` via Prometheus, que já coleta essa métrica) com CPU como gatilho de segurança (`70%`). `minReplicaCount: 1`, `maxReplicaCount: 4` — por ser o serviço crítico de SLO (99.9% / P99 250ms).
- `ngo-service` e `volunteer-service` permanecem no HPA nativo (CPU `averageUtilization: 70%`, ajustado de 80% para reagir mais cedo) — ainda sem baseline de tráfego calibrada para migrar para KEDA.
- O `ScaledObject` do `donation-service` é gerenciado via GitOps (`eks/deployments/keda/donation-scaling.yaml`).

## 9. Aplicações envolvidas

As melhorias abrangem os seguintes componentes do projeto:

- `donation-service` (Go + PostgreSQL via Flyway, scaling via KEDA)
- `ngo-service` (Python + PostgreSQL via Flyway, HPA nativo)
- `volunteer-service` (Python + DynamoDB, HPA nativo)
- `postgres` via Docker Compose
- `localstack` para emulação de AWS local
- `KEDA` como add-on de cluster, geridos via pipeline (instalação) e GitOps (configuração de scaling)

## 10. Benefícios gerais

- Ambiente local mais confiável e previsível.
- Aproximação mais segura entre desenvolvimento local e deploy em AWS.
- Menos dependência de intervenção manual para criar recursos ou esperar inicialização.
- Ciclo de vida de banco de dados imutável, versionado e auditável no próprio repositório.
- Maior estabilidade para testes de integração e desenvolvimento contínuo.
- Uso de recursos de cluster mais eficiente e seguro (rightsizing por workload, sem risco de OOM nos serviços Python).
- Scaling guiado pelo sinal correto de carga (tráfego HTTP) no serviço crítico de SLO, em vez de apenas CPU, sem exigir nenhuma permissão AWS adicional além do que já está em uso no Lab.
