#!/bin/bash
set -e

CLUSTER_NAME="toggle-cluster"

echo "=== Criando registro Docker local para imagens ==="
docker run -d --restart=always -p 5000:5000 --name kind-registry registry:2 || echo "Registro já existe"

echo "=== Conectando registry à rede do Kind ==="
docker network connect kind kind-registry || true

echo "=== Criando cluster Kind '${CLUSTER_NAME}' ==="
kind create cluster --name "${CLUSTER_NAME}" --config kind-cluster.yaml || echo "Cluster já existe"

echo "=== Build image de analytics ==="
docker build -t toggle-master-microservices-analytics-service ../analytics-service/

echo "=== Criando tag image de analytics ==="
docker tag toggle-master-microservices-analytics-service localhost:5000/toggle-master-microservices-analytics-service

echo "=== Enviando imagem para o registry local ==="
docker push localhost:5000/toggle-master-microservices-analytics-service

echo "=== Criando namespace toggle-master ==="
kubectl apply -f namespace.yaml

echo "=== Aplicando MetalLB no cluster ==="
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

echo "=== Aguardando MetalLB pods ficarem prontos ==="
kubectl wait --namespace metallb-system --for=condition=available deployment --all --timeout=120s

echo "=== Aplicando configuração do MetalLB ==="
kubectl apply -f metallb-config.yaml

echo "=== Criando Pod analytics ==="
kubectl apply -f ../analytics-service/analytics-pod.yaml -n toggle-master

echo "=== Criando Service LoadBalancer ==="
kubectl apply -f analytics-service.yaml -n toggle-master

echo "=== Esperando Service receber EXTERNAL-IP ==="
EXTERNAL_IP=""
while [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" = "<pending>" ]; do
    sleep 3
    EXTERNAL_IP=$(kubectl get svc analytics-service -n toggle-master -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
done

echo "=== Service LoadBalancer pronto com EXTERNAL-IP: $EXTERNAL_IP ==="
kubectl get pods -n toggle-master
kubectl get svc -n toggle-master
