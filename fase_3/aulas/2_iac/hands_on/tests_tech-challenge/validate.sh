#!/bin/bash
set -e

export AWS_PAGER=""

PROJECT_TAG="toggle-master"

ENDPOINT="--endpoint-url=http://localhost:4566"
REGION="--region us-east-1"
PROFILE="--profile localstack"

echo "🔎 Validando recursos do projeto: $PROJECT_TAG"
echo

echo "🌐 VPC"
aws ec2 describe-vpcs $ENDPOINT $REGION $PROFILE \
  --filters "Name=tag:project,Values=$PROJECT_TAG" \
  --query "Vpcs[*].{ID:VpcId,CIDR:CidrBlock}"

echo
echo "🧱 Subnets"
aws ec2 describe-subnets $ENDPOINT $REGION $PROFILE \
  --filters "Name=tag:project,Values=$PROJECT_TAG" \
  --query "Subnets[*].{ID:SubnetId,VPC:VpcId,CIDR:CidrBlock}"

echo
echo "🌍 IGW"
aws ec2 describe-internet-gateways $ENDPOINT $REGION $PROFILE \
  --filters "Name=tag:project,Values=$PROJECT_TAG" \
  --query "InternetGateways[*].{ID:InternetGatewayId}"

echo
echo "🚪 NAT"
aws ec2 describe-nat-gateways $ENDPOINT $REGION $PROFILE \
  --filter "Name=tag:project,Values=$PROJECT_TAG" \
  --query "NatGateways[*].{ID:NatGatewayId,State:State}"

echo
echo "🧭 Route Tables"
aws ec2 describe-route-tables $ENDPOINT $REGION $PROFILE \
  --filters "Name=tag:project,Values=$PROJECT_TAG" \
  --query "RouteTables[*].{ID:RouteTableId,VPC:VpcId}"

echo
echo "✅ Concluído"
