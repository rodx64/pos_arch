#!/bin/bash
set -e

PROJECT_TAG="toggle-master"

ENDPOINT="--endpoint-url=http://localhost:4566"
REGION="--region us-east-1"
PROFILE="--profile localstack"

echo "🔎 Validando recursos do projeto: $PROJECT_TAG"
echo

########################################
echo "🌐 VPC do projeto"
########################################

VPC_COUNT=$(aws ec2 describe-vpcs $ENDPOINT $REGION $PROFILE \
  --filters "Name=tag:project,Values=$PROJECT_TAG" \
  --query "length(Vpcs)")

if [ "$VPC_COUNT" -eq 0 ]; then
  echo "❌ VPC do projeto não encontrada"
  exit 1
fi

echo "VPC(s) do projeto: $VPC_COUNT"

########################################
echo "🧱 Subnets do projeto"
########################################

SUBNET_COUNT=$(aws ec2 describe-subnets $ENDPOINT $REGION $PROFILE \
  --filters "Name=tag:project,Values=$PROJECT_TAG" \
  --query "length(Subnets)")

echo "Subnets do projeto: $SUBNET_COUNT"

########################################
echo "🌍 Internet Gateway do projeto"
########################################

IGW_COUNT=$(aws ec2 describe-internet-gateways $ENDPOINT $REGION $PROFILE \
  --filters "Name=tag:project,Values=$PROJECT_TAG" \
  --query "length(InternetGateways)")

echo "IGWs do projeto: $IGW_COUNT"

########################################
echo "🚪 NAT Gateways do projeto"
########################################

NAT_COUNT=$(aws ec2 describe-nat-gateways $ENDPOINT $REGION $PROFILE \
  --filter "Name=tag:project,Values=$PROJECT_TAG" \
  --query "length(NatGateways)")

echo "NAT Gateways do projeto: $NAT_COUNT"

########################################
echo "🧭 Route Tables do projeto"
########################################

RTB_COUNT=$(aws ec2 describe-route-tables $ENDPOINT $REGION $PROFILE \
  --filters "Name=tag:project,Values=$PROJECT_TAG" \
  --query "length(RouteTables)")

echo "Route Tables do projeto: $RTB_COUNT"

echo
echo "✅ Validação do projeto concluída"
