#!/bin/bash
set -e

CLUSTER_NAME="toggle-cluster"

echo "=== Criando registro Docker local para imagens ==="
docker run -d --restart=always -p 5000:5000 --name kind-registry registry:2 || echo "Registro já existe"

echo "=== Conectando registry à rede do Kind ==="
docker network connect kind kind-registry || true

echo "=== Criando cluster Kind '${CLUSTER_NAME}' ==="
kind create cluster --name "${CLUSTER_NAME}" --config ../kind-cluster.yaml || echo "Cluster já existe"

echo "=== Build das images ==="
docker build -t toggle-master-microservices-analytics-service ../../analytics-service/
docker build -t toggle-master-microservices-auth-service ../../auth-service/
# docker build -t toggle-master-microservices-evaluation-service ../../evaluation-service/
docker build -t toggle-master-microservices-flag-service ../../flag-service/
# docker build -t toggle-master-microservices-targeting-service ../../targeting-service/

echo "=== Criando tag das imagens ==="
docker tag toggle-master-microservices-analytics-service localhost:5000/toggle-master-microservices-analytics-service
docker tag toggle-master-microservices-auth-service localhost:5000/toggle-master-microservices-auth-service
# docker tag toggle-master-microservices-evaluation-service localhost:5000/toggle-master-microservices-evaluation-service
docker tag toggle-master-microservices-flag-service localhost:5000/toggle-master-microservices-flag-service
# docker tag toggle-master-microservices-targeting-service localhost:5000/toggle-master-microservices-targeting-service

echo "=== Enviando imagens para o registry local ==="
docker push localhost:5000/toggle-master-microservices-analytics-service
docker push localhost:5000/toggle-master-microservices-auth-service
# docker push localhost:5000/toggle-master-microservices-evaluation-service
docker push localhost:5000/toggle-master-microservices-flag-service
# docker push localhost:5000/toggle-master-microservices-targeting-service    

echo "=== Criando namespace toggle-master ==="
kubectl apply -f ../namespace.yaml

echo "=== Aplicando MetalLB no cluster ==="
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

echo "=== Aguardando MetalLB pods ficarem prontos ==="
kubectl wait --namespace metallb-system --for=condition=available deployment --all --timeout=120s

echo "=== Aplicando configuração do MetalLB ==="
kubectl apply -f ../metallb-config.yaml

echo "=== Aplicando Deployments  ==="
kubectl apply -f ../deployments/analytics.yaml -n toggle-master
kubectl apply -f ../deployments/auth.yaml -n toggle-master
kubectl apply -f ../deployments/flag.yaml -n toggle-master

echo "=== Criando Service LoadBalancer ==="
kubectl apply -f ../services/analytics-service.yaml -n toggle-master
kubectl apply -f ../services/auth-service.yaml -n toggle-master
kubectl apply -f ../services/flag-service.yaml -n toggle-master

echo "=== Pods e Services ==="
kubectl get pods -n toggle-master
kubectl get svc -n toggle-master
