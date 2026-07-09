# Melhorias implementadas no Tech Challenge

Este documento lista as melhorias aplicadas no challenge do `tech_challenge`, cobrindo todos os serviços e aplicações do projeto, incluindo infra local e ajustes de código.

A organização abaixo foi pensada em eixos temáticos: infraestrutura, comportamento dos serviços, escalabilidade e experiência do usuário, para facilitar a navegação e a compreensão do contexto de cada mudança.

## 1. Infraestrutura local, persistência e dados

### 1.1. Ambiente local com LocalStack

- Adicionado suporte ao [LocalStack][localstack] para permitir testes AWS locais sem depender de contas pagas.
- Configurado `SERVICES=sqs,dynamodb` no [`docker-compose.yml`][docker-compose] para ativar apenas os serviços usados pelo projeto.
- Criado [`init-aws.sh`][init-aws] como hook de startup do LocalStack para provisionar recursos necessários automaticamente.
- Tornada a inicialização do LocalStack idempotente para reinícios seguros:
  - fila SQS: `donation-queue`
  - tabela DynamoDB: `volunteer-table`

### 1.2. Banco de dados e bootstrap local

- Criado o [`init-postgres.sh`][init-postgres] para criar o banco e a estrutura de tabelas corretamente no PostgreSQL sem erro de sintaxe.
- Ajustado o [`docker-compose.yml`][docker-compose] para expor o PostgreSQL em `5432:5432`, permitindo conexão por DBeaver e outras ferramentas externas.
- Organizado `depends_on` para que `postgres` e `localstack` fiquem prontos antes dos serviços que dependem deles.
- Melhorado o fluxo de bootstrap do banco para não interromper a inicialização do container.
- Preservado os dados do PostgreSQL em volume nomeado para facilitar testes locais persistentes.

### 1.3. Resiliência e provisionamento de recursos

- Implementado `ensure_dynamodb_table(...)` para verificar e criar `volunteer-table` automaticamente, evitando erros de tabela inexistente.

### 1.4. Versionamento com Flyway

- Adotado o **Flyway** para gerenciamento e versionamento profissional de schemas nos bancos de dados relacionais (`donation-service` e `ngo-service`), com migrações aplicadas via [migration do donation-service][donation-migration], [migration do ngo-service][ngo-migration] e o módulo [db-migrations][db-migrations].
- Separação de responsabilidades: as aplicações não criam mais as próprias tabelas em tempo de execução, delegando a função para scripts versionados (ex: `V1__initial_schema.sql`).
- Implementação de imagens Docker exclusivas (`Dockerfile.migration`) baseadas no Flyway, mantendo os containers das aplicações enxutos e focados na regra de negócio.
- Criação de um módulo exclusivo no **Terraform** (`db-migrations`) orquestrado via **Terragrunt**, disparando *Kubernetes Jobs* que garantem a criação/atualização das tabelas antes que as aplicações subam no EKS.
- Criação de [workflow][workflow-migration] exclusivo da migração.

## 2. Resiliência de serviços

Este bloco reúne as melhorias voltadas ao comportamento operacional dos serviços, especialmente no que diz respeito à inicialização segura e à dependência de componentes externos.

### 2.1. Inicialização e dependências externas

- Adicionada função genérica `wait_for_service(...)` para aguardar disponibilidade de AWS/LocalStack antes de prosseguir, com a lógica implementada no [`volunteer-service`][volunteer-app].

### 2.2. Endpoint sintético `/cpu` para testes de carga

- Implementada a rota `/cpu` em `donation-service` (Go), `ngo-service` e `volunteer-service` (Flask). 

  Endpoint sintético de estresse de CPU, sem efeito sobre banco de dados ou fila, aceitando `?duration_ms=N` (padrão 50ms, máximo 500ms) para controlar a intensidade da carga.
- Utilizado o script `k6-load-test.yaml` para estressar esse endpoint `/cpu` nos 3 serviços. 
- Objetivo: gerar um sinal real de CPU para calibrar thresholds de HPA/KEDA e validar o rightsizing com dados de carga reproduzíveis, em vez de estimativa pura.

## 3. Scaling baseado em tráfego com KEDA (`donation-service`)

A decisão de escalabilidade foi tomada com foco no serviço mais crítico da plataforma, buscando alinhar a automação de scaling com sinais reais de tráfego e de carga.

### 3.1. Contexto da decisão

- Avaliada a viabilidade de scaling baseado em fila (SQS): descartada por ora, já que a `donation-queue` hoje só tem produtor (`donation-service`) — não há consumidor no código, logo não há profundidade de fila com relação causal para escalar contra. A implementação ficou registrada no [ScaledObject do donation-service][keda-scaledobject] e na documentação de [rightsizing][rightsizing-doc].

### 3.2. Implementação prática

- Para o `donation-service`, substituído o HPA anterior por **KEDA**, escalando por **tráfego HTTP** (`sum(rate(http_requests_total{service="donation"}[2m]))` via Prometheus, que já coleta essa métrica) com CPU como gatilho de segurança (`70%`). `minReplicaCount: 1`, `maxReplicaCount: 4` — por ser o serviço crítico de SLO (99.9% / P99 250ms).
- `ngo-service` e `volunteer-service` permanecem no HPA nativo (CPU `averageUtilization: 70%`, ajustado de 80% para reagir mais cedo) — ainda sem baseline de tráfego calibrada para migrar para KEDA.
- O `ScaledObject` do `donation-service` é gerenciado via GitOps (`eks/deployments/keda/donation-scaling.yaml`).

## 4. Adição de um Frontend com Identidade Visual

Este bloco consolida as melhorias relacionadas à camada de interface, destacando a evolução da experiência do usuário e da identidade visual da plataforma.

### 4.1. Experiência visual e UX

Após a estabilização da infraestrutura, focamos na experiência do usuário (UX) e na identidade visual da plataforma, tratando o [frontend][frontend] com padrões de design modernos:

- UI/UX:
  - Header Unificado: Substituição dos componentes isolados por um cabeçalho fixo e escuro (.main-header), otimizando o uso de espaço e a legibilidade das informações de status e totais de doação.
  - Integração Visual com Docusaurus: Mapeamento dos assets de marca (logo.png, banner.png) para o frontend, mantendo a consistência visual entre a plataforma operacional e a documentação técnica.
  - Banner de Impacto: Implementação de um banner central, com texto institucional sobreposto e centralizado, reforçando o propósito da Solidary Tech.

### 4.2. Arquitetura de interface

- Estruturação do layout com CSS moderno (Flexbox/Grid), garantindo responsividade e mantendo a identidade visual profissional em diversos tamanhos de tela.

## 5. Integração com Docusaurus

- O projeto passou a utilizar o **Docusaurus** como plataforma de documentação técnica e operacional, consolidando em um único local os principais conteúdos de arquitetura, execução, troubleshooting e contexto do desafio, com a configuração central em [docusaurus.config.ts][docusaurus-config] e os conteúdos em [docs][docusaurus-docs].
- A documentação foi organizada para refletir melhor a evolução do projeto, incluindo a camada de frontend, a infraestrutura e os fluxos de operação.
- O Docusaurus também contribui para uma experiência mais profissional para quem consome a documentação, permitindo navegação estruturada, busca e leitura mais agradável em comparação com arquivos estáticos isolados.

### Benefícios da adoção do Docusaurus

- **Centralização da documentação**: evita dispersão de informações em vários arquivos e facilita o acesso rápido a conteúdos relevantes.
- **Melhor experiência de navegação**: estrutura por páginas, categorias e links internos facilita a localização de informações.
- **Facilidade de manutenção**: a documentação pode evoluir junto com o projeto de forma mais organizada e escalável.
- **Consistência visual**: permite alinhar a documentação com a identidade visual da plataforma e do frontend.
- **Melhor onboarding**: novos integrantes conseguem entender mais rapidamente o contexto, os serviços e os processos do projeto.
- **Escalabilidade**: o modelo é adequado para crescer com o projeto, incluindo versões, guias operacionais e tutoriais.

## 6. Aplicações envolvidas

Este resumo ajuda a localizar rapidamente onde cada melhoria foi aplicada dentro do ecossistema do projeto.

As melhorias abrangem os seguintes componentes do projeto:

- `donation-service` (Go + PostgreSQL via Flyway, scaling via KEDA)
- `ngo-service` (Python + PostgreSQL via Flyway, HPA nativo)
- `volunteer-service` (Python + DynamoDB, HPA nativo)
- `postgres` via Docker Compose
- `localstack` para emulação de AWS local
- `KEDA` como add-on de cluster, geridos via pipeline (instalação) e GitOps (configuração de scaling)

## 7. Benefícios gerais

Este bloco reúne os ganhos de negócio e de operação obtidos com a consolidação das melhorias descritas ao longo do documento.

- Ambiente local mais confiável e previsível.
- Aproximação mais segura entre desenvolvimento local e deploy em AWS.
- Menos dependência de intervenção manual para criar recursos ou esperar inicialização.
- Ciclo de vida de banco de dados imutável, versionado e auditável no próprio repositório.
- Maior estabilidade para testes de integração e desenvolvimento contínuo.
- Uso de recursos de cluster mais eficiente e seguro (rightsizing por workload, sem risco de OOM nos serviços Python).
- Scaling guiado pelo sinal correto de carga (tráfego HTTP) no serviço crítico de SLO, em vez de apenas CPU, sem exigir nenhuma permissão AWS adicional além do que já está em uso no Lab.

[docker-compose]: ../solidary-tech/local/docker-compose.yml
[localstack]: ../solidary-tech/local/
[init-aws]: ../solidary-tech/local/init-aws.sh
[init-postgres]: ../solidary-tech/local/init-postgres.sh
[ngo-dockerfile]: ../solidary-tech/services/ngo-service/Dockerfile
[volunteer-dockerfile]: ../solidary-tech/services/volunteer-service/Dockerfile
[volunteer-app]: ../solidary-tech/services/volunteer-service/app.py
[donation-migration]: ../solidary-tech/services/donation-service/Dockerfile.migration
[ngo-migration]: ../solidary-tech/services/ngo-service/Dockerfile.migration
[db-migrations]: ../solidary-tech/db-migrations/dev/terragrunt.hcl
[donation-main]: ../solidary-tech/services/donation-service/main.go
[ngo-app]: ../solidary-tech/services/ngo-service/app.py
[keda-scaledobject]: ../solidary-tech/eks/deployments/keda/donation-scaling.yaml
[rightsizing-doc]: ../solidary-tech/doc/4_RIGHTSIZING.md
[frontend]: ../solidary-tech/front
[docusaurus-config]: ../solidary-tech/docs/docusaurus.config.ts
[docusaurus-docs]: ../solidary-tech/docs/docs
[workflow-migration]: ../../../.github/workflows/cd-migrations.yml
