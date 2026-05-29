#!/bin/bash
set -e

echo "🚀 Inicializando recursos AWS locais no LocalStack..."

awslocal sqs create-queue --queue-name donation-queue

awslocal dynamodb create-table \
  --table-name VolunteerTable \
  --attribute-definitions AttributeName=volunteer_id,AttributeType=S \
  --key-schema AttributeName=volunteer_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

echo "✅ LocalStack AWS resources created."
