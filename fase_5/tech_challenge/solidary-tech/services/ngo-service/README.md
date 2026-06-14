# NGO Service

## Visão geral

O `ngo-service` é um backend em Flask que gerencia o cadastro e a listagem de ONGs para a plataforma Solidary Tech.

## Stack

- Python 3.13
- Flask
- PostgreSQL
- psycopg2
- Gunicorn
- python-dotenv

## Endpoints

- `GET /health`
  - Retorna o estado de saúde do serviço.
- `GET /ngos`
  - Retorna a lista de ONGs cadastradas.
- `POST /ngos`
  - Cria um novo registro de ONG.
  - Campos obrigatórios no corpo JSON: `name`, `email`, `cause`, `city`.

## Configuração de runtime

Porta padrão: `8081`

Variáveis de ambiente:

- `DATABASE_URL` - string de conexão PostgreSQL
- `PORT` - porta da aplicação (padrão `8081`)
- `HOST` - endereço de host (padrão `127.0.0.1`)

### Exemplo de `.env`

```env
DATABASE_URL=postgres://postgres:password@postgres:5432/ngo_db
PORT=8081
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
docker build -t solidary-tech-ngo-service .
docker run --env-file .env -p 8081:8081 solidary-tech-ngo-service
```

### Usando LocalStack

Este serviço não consome diretamente AWS, então não exige configuração específica de LocalStack para o backend. Basta garantir que o PostgreSQL local esteja disponível e o `DATABASE_URL` aponte para sua instância de banco.

## Esquema de banco de dados

O serviço usa a tabela `ngos` com as colunas:

- `id`
- `name`
- `email`
- `cause`
- `city`
- `created_at`

O arquivo `db/init.sql` contém o script de criação e dados iniciais.

## Testes

Execute os testes unitários com:

```bash
python -m unittest test_app.py
```
<!--  -->
