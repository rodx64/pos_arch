# Donation Service

## Visão geral

O `donation-service` é um backend em Go que gerencia a criação e a listagem de doações para a plataforma Solidary Tech. Ele persiste registros no PostgreSQL e opcionalmente publica eventos de doação no AWS SQS.

## Stack

- Go 1.25
- PostgreSQL
- AWS SDK para SQS
- Suporte a LocalStack para testes locais

## Endpoints

- `GET /health`
  - Retorna o estado de saúde do serviço.
- `GET /donations`
  - Retorna a lista de doações.
- `POST /donations`
  - Cria um novo registro de doação.
  - Payload JSON esperado: `ngo_id`, `amount`, `donor_name`.

## Configuração de runtime

Porta padrão: `8082`

Variáveis de ambiente:

- `DATABASE_URL` - string de conexão PostgreSQL
- `PORT` - porta da aplicação (padrão `8082`)
- `HOST` - endereço de host (padrão `127.0.0.1`)
- `AWS_REGION` - região AWS para SQS
- `AWS_ENDPOINT_URL` - endpoint AWS opcional (LocalStack)
- `AWS_SQS_URL` - URL da fila SQS para eventos
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` - credenciais AWS

### Exemplo de `.env`

```env
DATABASE_URL=postgres://postgres:password@postgres:5432/donation_db
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_SQS_URL=http://localstack:4566/000000000000/donation-queue
AWS_ENDPOINT_URL=http://localstack:4566
PORT=8082
```

## Desenvolvimento local

Compile localmente:

```bash
go build -o donation-service .
```

Execute localmente:

```bash
./donation-service
```

Ou com Docker:

```bash
docker build -t solidary-tech-donation-service .
docker run --env-file .env -p 8082:8082 solidary-tech-donation-service
```

### Usando LocalStack

Para testes locais com LocalStack, configure `AWS_ENDPOINT_URL` para `http://localstack:4566` e `AWS_SQS_URL` para a fila simulada, como `http://localstack:4566/000000000000/donation-queue`.

O serviço habilita o envio de mensagens SQS apenas quando `AWS_SQS_URL` e `AWS_REGION` estiverem definidos.

## Notas de comportamento

- Doações são armazenadas na tabela `donations`.
- Toda doação criada recebe `status: APPROVED`.
- Se `AWS_SQS_URL` estiver configurada, o serviço envia um evento SQS em background.

## Esquema de banco de dados

O arquivo `db/init.sql` define a tabela `donations` com as colunas:

- `id`
- `ngo_id`
- `amount`
- `donor_name`
- `status`
- `created_at`

