#!/bin/bash
set -e

echo "🚀 Inicializando recursos AWS locais no LocalStack..."

# ==========================
# 🔸 Criar fila SQS
# ==========================
echo "📬 Criando fila SQS do serviço Analytics..."
awslocal sqs create-queue \
  --queue-name toggle-analytics-queue

# ==========================
# 🔸 Criar tabela DynamoDB
# ==========================
echo "🧩 Criando tabela DynamoDB 'analytics_events'..."

awslocal dynamodb create-table \
  --table-name analytics_events \
  --attribute-definitions \
      AttributeName=event_id,AttributeType=S \
  --key-schema \
      AttributeName=event_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

echo "✅ Recursos criados com sucesso!"
