#!/bin/bash
set -e

CLUSTER_NAME="toggle-cluster"
REGISTRY_NAME="kind-registry"

echo "=== Removendo ingress-nginx bare-metal ==="
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/baremetal/namespaced/nginx-ingress-controller.yaml || true

echo "=== Removendo MetalLB e config ==="
kubectl delete -f ../metallb-config.yaml || true
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml || true

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

echo "=== Removendo imagens locais ==="
docker rmi -f toggle-master-microservices-analytics-service 2>/dev/null || true
docker rmi -f toggle-master-microservices-auth-service 2>/dev/null || true
docker rmi -f toggle-master-microservices-evaluation-service 2>/dev/null || true
docker rmi -f toggle-master-microservices-flag-service 2>/dev/null || true
docker rmi -f toggle-master-microservices-targeting-service 2>/dev/null || true

echo "=== Removendo imagem registry:2 ==="
docker rmi -f registry:2 2>/dev/null || true

echo "=== Limpeza concluída ==="
