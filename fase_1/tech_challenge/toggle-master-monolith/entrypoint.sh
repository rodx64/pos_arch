#!/bin/sh
set -e

REGION=${AWS_REGION:-us-east-1}
export AWS_REGION=$REGION

LOCALSTACK=${LOCALSTACK:-false}
LOCALSTACK_HOST=${LOCALSTACK_HOST:-localstack}
LOCALSTACK_PORT=${LOCALSTACK_PORT:-4566}

if [ "$LOCALSTACK" = "true" ]; then
  AWS_ENDPOINT_URL=${AWS_ENDPOINT_URL:-http://$LOCALSTACK_HOST:$LOCALSTACK_PORT}
  export AWS_ACCESS_KEY_ID=test
  export AWS_SECRET_ACCESS_KEY=test
  echo "⚡ Usando LocalStack em $AWS_ENDPOINT_URL"
fi

if [ "$LOCALSTACK" = "true" ]; then
  echo "🔄 Aguardando LocalStack..."
  until curl -s $AWS_ENDPOINT_URL/_localstack/health | grep '"ssm": "running"' >/dev/null && \
        curl -s $AWS_ENDPOINT_URL/_localstack/health | grep '"secretsmanager": "running"' >/dev/null; do
    echo "LocalStack ainda não está pronto, aguardando 2s..."
    sleep 2
  done
  echo "✅ LocalStack pronto!"
fi

echo "⚙️ Inicializando banco de dados via Flask CLI..."
flask init-db

echo "🚀 Iniciando Gunicorn..."
exec gunicorn --bind 0.0.0.0:5000 app:app
