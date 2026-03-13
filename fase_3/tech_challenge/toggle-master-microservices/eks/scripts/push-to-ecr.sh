#!/bin/bash
set -e

AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="447941455905"
ECR_BASE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/toggle-master"

IMAGES=(
  "analytics-service"
  "auth-service"
  "evaluation-service"
  "flag-service"
  "targeting-service"
)

echo "=================================================="
echo " 🚀 Build + Push das Imagens para o AWS ECR"
echo "=================================================="
echo ""

# -----------------------------------------------------
# 1) LOGIN NO ECR
# -----------------------------------------------------
echo "=== Efetuando login no ECR ==="
aws ecr get-login-password --region $AWS_REGION \
  | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# -----------------------------------------------------
# 2) BUILD + TAG + PUSH
# -----------------------------------------------------
for SERVICE in "${IMAGES[@]}"; do
  LOCAL_NAME="toggle-master-microservices-${SERVICE}"
  ECR_TAG="${ECR_BASE}/${SERVICE}:latest"

  echo ""
  echo "-------------------------------------------"
  echo " 📦 Buildando imagem do serviço: ${SERVICE}"
  echo "-------------------------------------------"

  docker build -t "${LOCAL_NAME}" "../../${SERVICE}/"

  echo "🏷  Gerando tag: ${ECR_TAG}"
  docker tag "${LOCAL_NAME}" "${ECR_TAG}"

  echo "⬆  Enviando para ECR..."
  docker push "${ECR_TAG}"

  echo "✔  ${SERVICE} enviado com sucesso!"
done

echo ""
echo "=================================================="
echo " 🎉 Todas as imagens foram publicadas no ECR!"
echo "=================================================="
