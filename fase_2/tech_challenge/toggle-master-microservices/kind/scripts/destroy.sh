#!/bin/bash
set -e

CLUSTER_NAME="toggle-cluster"
REGISTRY_NAME="kind-registry"

echo "=== Deletando cluster Kind '${CLUSTER_NAME}' ==="
kind delete cluster --name "${CLUSTER_NAME}" || echo "Cluster já removido ou não existe"

echo "=== Parando e removendo registry local '${REGISTRY_NAME}' ==="
docker stop "${REGISTRY_NAME}" 2>/dev/null || true
docker rm "${REGISTRY_NAME}" 2>/dev/null || true

echo "=== Removendo imagens Docker do registry local ==="
docker image rm localhost:5000/toggle-master-microservices-analytics-service 2>/dev/null || true
docker image rm localhost:5000/toggle-master-microservices-auth-service 2>/dev/null || true
docker image rm localhost:5000/toggle-master-microservices-evaluation-service 2>/dev/null || true
docker image rm localhost:5000/toggle-master-microservices-flag-service 2>/dev/null || true
docker image rm localhost:5000/toggle-master-microservices-targeting-service 2>/dev/null || true

docker rmi -f toggle-master-microservices-analytics-service 2>/dev/null || true
docker rmi -f toggle-master-microservices-auth-service 2>/dev/null || true
docker rmi -f toggle-master-microservices-evaluation-service 2>/dev/null || true
docker rmi -f toggle-master-microservices-flag-service 2>/dev/null  || true
docker rmi -f toggle-master-microservices-targeting-service 2>/dev/null || true
docker rmi -f registry:2 2>/dev/null || true

echo "=== Limpeza concluída ==="
