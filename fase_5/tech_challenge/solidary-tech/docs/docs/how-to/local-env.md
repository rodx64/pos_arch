# Ambiente de Desenvolvimento

Para garantir custo zero durante o desenvolvimento, a Solidary Tech adota a estratégia **Local-First** — nenhum recurso AWS é provisionado para o ambiente DEV.

## Ferramentas

| Ferramenta | Papel | Documentação |
|---|---|---|
| [Docker][docker] + [Docker Compose][compose] | Orquestra PostgreSQL e LocalStack localmente | [`local/docker-compose.yml`][docker-compose-file] |
| [LocalStack][localstack] | Emula SQS (`donation-queue`) e DynamoDB (`volunteer-table`) | [`local/init-aws.sh`][init-aws-file] |
| [Kind][kind] | Cluster Kubernetes local para validação de manifestos | — |
| [Terraform][terraform] / [Terragrunt][terragrunt] | IaC com `mock_outputs` para `plan`/`validate` sem cluster real | [`observability/dev/terragrunt.hcl`][tg-dev-obs] |

## Subindo o ambiente local

```bash
# 1. Iniciar Postgres + LocalStack
cd local/
docker compose up -d

# 2. Aguardar o LocalStack estar healthy e os recursos AWS serem criados
# (o init-aws.sh é executado automaticamente via localstack init hook)
docker compose logs -f localstack

# 3. Verificar recursos
awslocal sqs get-queue-url --queue-name donation-queue
awslocal dynamodb describe-table --table-name volunteer-table
```

## Estratégia de FinOps Local-First

O ambiente DEV na AWS foi descontinuado. O impacto financeiro:

| Cenário | Custo |
|---|---|
| DEV local (estratégia atual) | **$0/mês** |
| DEV na AWS (mesma topologia, always-on) | **~$237/mês** |
| Economia anual | **~$2.844/ano** |

A validação da IaC (Terraform/Terragrunt) usa `mock_outputs` para rodar `plan`/`validate` sem depender do estado remoto real do EKS — a esteira roda localmente e nos PRs sem custo de infraestrutura.

## Validação de IaC sem cluster

```hcl
# observability/dev/terragrunt.hcl
mock_outputs_allowed_terraform_commands = ["validate", "plan"]
mock_outputs = {
  eks_cluster_endpoint = "https://mock"
  eks_cluster_ca       = "bW9jaw=="
  eks_cluster_token    = "mock"
}
```

Isso permite que `terragrunt validate` e `terragrunt plan` rodem no CI (PRs) sem um cluster EKS real provisionado.

## Executando os serviços localmente (Docker Compose)

O caminho recomendado para rodar a aplicação localmente é via `docker-compose.yml`, que já orquestra os serviços junto ao Postgres e LocalStack. Cada serviço lê suas variáveis a partir de um arquivo `.env` localizado na raiz do próprio serviço.

### Variáveis necessárias por serviço

**`services/donation-service/.env`**
```env
# Postgres local (docker-compose sobe em localhost:5432, senha padrão definida no docker-compose.yml)
DATABASE_URL=postgresql://postgres:password@postgres:5432/donation_db

# SQS emulado pelo LocalStack (credenciais fictícias obrigatórias para o SDK AWS)
AWS_SQS_URL=http://localstack:4566/000000000000/donation-queue
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test

# Redireciona o SDK do SQS para o LocalStack (mesmo padrão do volunteer-service)
AWS_ENDPOINT_URL=http://localstack:4566

# Porta e log
PORT=8082
LOG_LEVEL=INFO

# OTel — desabilitar ou apontar para localhost se não houver otel-collector rodando
OTEL_EXPORTER_OTLP_ENDPOINT=
```

**`services/ngo-service/.env`**
```env
DATABASE_URL=postgresql://postgres:password@postgres:5432/ngo_db
AWS_REGION=us-east-1
PORT=8081
LOG_LEVEL=INFO
OTEL_EXPORTER_OTLP_ENDPOINT=
```

**`services/volunteer-service/.env`**
```env
# DynamoDB emulado pelo LocalStack
AWS_DYNAMODB_TABLE=volunteer-table
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_ENDPOINT_URL=http://localstack:4566

PORT=8083
LOG_LEVEL=INFO
OTEL_EXPORTER_OTLP_ENDPOINT=
```

> **Por que `AWS_ACCESS_KEY_ID=test`?** O SDK AWS exige que as variáveis de credencial estejam presentes mesmo quando apontando para o LocalStack — os valores são ignorados pelo emulador, mas a ausência delas causa erro de inicialização.

> **`OTEL_EXPORTER_OTLP_ENDPOINT` vazio:** sem o `otel-collector` rodando localmente, deixar a variável em branco desabilita a exportação silenciosamente na maioria dos SDKs. Alternativa: subir o `otel-collector` como serviço adicional no `docker-compose.yml` apontando para Prometheus/Loki locais.

### Subindo tudo

```bash
cd local/
docker compose up -d --build

# Verificar que todos os serviços estão healthy
docker compose ps

# Testar endpoints
curl http://localhost:8081/ngos
curl http://localhost:8082/donations
curl http://localhost:8083/volunteers
```

---

## Validação estrutural de manifestos com Kind

O Kind permite tanto a validação estrutural dos manifestos Kubernetes (sintaxe YAML, RBAC, tipos de recursos) quanto a execução real da aplicação — desde que os três ajustes abaixo sejam aplicados.

```bash
kind create cluster --name solidary-tech-local
kubectl cluster-info --context kind-solidary-tech-local
```

Para que os deployments de `eks/` possam ser aplicados num Kind local sem falhar, três ajustes são necessários:

**1. Criar os Secrets manualmente** com os mesmos valores do `.env` local, em vez de depender do módulo `k8s-secrets` do Terraform:

```bash
kubectl create namespace solidary-tech

kubectl create secret generic donation-secret -n solidary-tech \
  --from-literal=DATABASE_URL='postgresql://postgres:password@host.docker.internal:5432/donation_db' \
  --from-literal=AWS_SQS_URL='http://host.docker.internal:4566/000000000000/donation-queue'

kubectl create secret generic ngo-secret -n solidary-tech \
  --from-literal=DATABASE_URL='postgresql://postgres:password@host.docker.internal:5432/ngo_db'

kubectl create secret generic volunteer-secret -n solidary-tech \
  --from-literal=AWS_DYNAMODB_TABLE='volunteer-table'
```

> `host.docker.internal` resolve para o host da máquina a partir de dentro do Kind — substitui `localhost` para alcançar o Postgres e o LocalStack que sobem pelo `docker compose`.

**2. Substituir as imagens ECR por builds locais** nos deployments — as imagens `608737466163.dkr.ecr.us-east-1.amazonaws.com/...` não são acessíveis sem autenticação AWS:

```bash
# Build local das imagens
docker build -t solidary-tech/donation-service:local services/donation-service
docker build -t solidary-tech/ngo-service:local      services/ngo-service
docker build -t solidary-tech/volunteer-service:local services/volunteer-service

# Carregar as imagens no cluster Kind
kind load docker-image solidary-tech/donation-service:local --name solidary-tech-local
kind load docker-image solidary-tech/ngo-service:local      --name solidary-tech-local
kind load docker-image solidary-tech/volunteer-service:local --name solidary-tech-local
```

E editar temporariamente os campos `image:` e `imagePullPolicy:` nos YAMLs antes de aplicar:

```yaml
# eks/deployments/donation.yaml — valores locais
image: solidary-tech/donation-service:local
imagePullPolicy: Never   # impede tentativa de pull do ECR
```

**3. Neutralizar as variáveis OTel** — o `otel-collector.monitoring.svc.cluster.local` não existe num Kind sem a stack de observabilidade. Adicionar um patch ou sobrescrever o valor no deployment para string vazia antes de aplicar.

[docker]: https://www.docker.com/
[compose]: https://docs.docker.com/compose/
[localstack]: https://www.localstack.cloud/
[kind]: https://kind.sigs.k8s.io/
[terraform]: https://developer.hashicorp.com/terraform
[terragrunt]: https://terragrunt.com/
[docker-compose-file]: https://github.com/rodx64/pos_arch/tree/develop/fase_5/tech_challenge/solidary-tech/local/docker-compose.yml
[init-aws-file]: https://github.com/rodx64/pos_arch/tree/develop/fase_5/tech_challenge/solidary-tech/local/init-aws.sh
[tg-dev-obs]: https://github.com/rodx64/pos_arch/blob/develop/fase_5/tech_challenge/solidary-tech/observability/dev/terragrunt.hcl
