#!/bin/bash
set -e

# hostname do banco no container docker (nome do serviço no docker-compose)
DB_HOST_NAME="db"

echo "📌 Inserindo valores no Parameter Store via SSM..."
awslocal ssm put-parameter --name "/togglemaster/DB_HOST" --value "$DB_HOST_NAME" --type String
awslocal ssm put-parameter --name "/togglemaster/DB_NAME" --value "togglemaster" --type String
awslocal ssm put-parameter --name "/togglemaster/DB_PORT" --value "5432" --type String
awslocal ssm put-parameter --name "/togglemaster/SECRET_NAME" --value "rds_localstack" --type String

echo "📌 Inserindo valores no Secrets Manager..."
awslocal secretsmanager create-secret \
  --name 'rds_localstack' \
  --secret-string '{"username":"user","password":"password"}'

echo "✅ Recursos criados no LocalStack com sucesso: "

# Valida valores inseridos
awslocal ssm get-parameter --name "/togglemaster/DB_HOST" --query "Parameter.Value" --output text
awslocal ssm get-parameter --name "/togglemaster/DB_NAME" --query "Parameter.Value" --output text
awslocal ssm get-parameter --name "/togglemaster/DB_PORT" --query "Parameter.Value" --output text
awslocal secretsmanager get-secret-value --secret-id 'rds_localstack' --query SecretString --output text
