# Volunteer Service

## Visão geral

O `volunteer-service` é um backend em Flask que registra voluntários e busca listas de voluntários por ONG. Ele armazena dados no DynamoDB e suporta LocalStack para testes locais.

## Stack

- Python 3.13
- Flask
- Boto3
- DynamoDB
- Gunicorn
- python-dotenv

## Endpoints

- `GET /health`
  - Retorna o estado de saúde do serviço.
- `POST /volunteers`
  - Registra um novo voluntário.
  - Campos obrigatórios no corpo JSON: `name`, `email`, `ngo_id`.
- `GET /volunteers/<ngo_id>`
  - Retorna voluntários registrados para uma ONG específica.

## Configuração de runtime

Porta padrão: `8083`

Variáveis de ambiente:

- `AWS_REGION` - região AWS (padrão `us-east-1`)
- `AWS_ENDPOINT_URL` - endpoint AWS opcional (LocalStack)
- `AWS_DYNAMODB_TABLE` - nome da tabela DynamoDB
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` - credenciais AWS
- `PORT` - porta da aplicação (padrão `8083`)
- `HOST` - endereço de host (padrão `127.0.0.1`)

### Exemplo de `.env`

```env
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_ENDPOINT_URL=http://localstack:4566
AWS_DYNAMODB_TABLE=VolunteerTable
PORT=8083
```

## Desenvolvimento local

Instale as dependências:

```bash
pip install -r requirements.txt
```

Execute localmente:

```bash
python app.py
```

Ou com Docker:

```bash
docker build -t solidary-tech-volunteer-service .
docker run --env-file .env -p 8083:8083 solidary-tech-volunteer-service
```

### Usando LocalStack

Para executar com LocalStack, defina `AWS_ENDPOINT_URL=http://localstack:4566` e `AWS_DYNAMODB_TABLE` para a tabela simulada. O serviço criará a tabela automaticamente se ela ainda não existir.

## Notas de comportamento

- Na inicialização, o serviço conecta ao DynamoDB e cria a tabela configurada se necessário.
- Os voluntários são armazenados com `volunteer_id`, `name`, `email`, `ngo_id` e `registered_at`.

<!--  -->
