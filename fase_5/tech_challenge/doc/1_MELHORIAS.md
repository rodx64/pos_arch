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

## 6. Versionamento de Banco de Dados com Flyway (Novo)

- Adotado o **Flyway** para gerenciamento e versionamento profissional de schemas nos bancos de dados relacionais (`donation-service` e `ngo-service`).
- Separação de responsabilidades: as aplicações não criam mais as próprias tabelas em tempo de execução, delegando a função para scripts versionados (ex: `V1__initial_schema.sql`).
- Implementação de imagens Docker exclusivas (`Dockerfile.migration`) baseadas no Flyway, mantendo os containers das aplicações enxutos e focados na regra de negócio.
- Criação de um módulo exclusivo no **Terraform** (`db-migrations`) orquestrado via **Terragrunt**, disparando *Kubernetes Jobs* que garantem a criação/atualização das tabelas antes que as aplicações subam no EKS.
- Adaptação dos pipelines de CI/CD (GitHub Actions) para realizar o build e push simultâneo da aplicação e da migração, com atualização automática das tags no repositório de infraestrutura.

## 7. Aplicações envolvidas

As melhorias abrangem os seguintes componentes do projeto:

- `donation-service` (Go + PostgreSQL via Flyway)
- `ngo-service` (Python + PostgreSQL via Flyway)
- `volunteer-service` (Python + DynamoDB)
- `postgres` via Docker Compose
- `localstack` para emulação de AWS local
- Infraestrutura EKS via Terraform/Terragrunt

## 8. Benefícios gerais

- Ambiente local mais confiável e previsível.
- Aproximação mais segura entre desenvolvimento local e deploy em AWS.
- Menos dependência de intervenção manual para criar recursos ou esperar inicialização.
- Ciclo de vida de banco de dados imutável, versionado e auditável no próprio repositório.
- Maior estabilidade para testes de integração e desenvolvimento contínuo.
