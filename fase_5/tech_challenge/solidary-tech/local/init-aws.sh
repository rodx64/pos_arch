#!/bin/bash
set -e

echo "🚀 Inicializando recursos AWS locais no LocalStack..."

if ! awslocal sqs get-queue-url --queue-name donation-queue >/dev/null 2>&1; then
  awslocal sqs create-queue --queue-name donation-queue
  echo "✅ Fila SQS criada: donation-queue"
else
  echo "⚠️ Fila SQS já existe: donation-queue"
fi

if ! awslocal dynamodb describe-table --table-name volunteer-table >/dev/null 2>&1; then
  awslocal dynamodb create-table \
    --table-name volunteer-table \
    --attribute-definitions AttributeName=volunteer_id,AttributeType=S \
    --key-schema AttributeName=volunteer_id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
  echo "✅ Tabela DynamoDB criada: volunteer-table"
else
  echo "⚠️ Tabela DynamoDB já existe: volunteer-table"
fi

echo "✅ LocalStack AWS resources ready."
