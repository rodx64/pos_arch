#!/bin/bash
set -e

CLUSTER_NAME="toggle-cluster"
REGISTRY_NAME="kind-registry"

echo "=== Criando registry Docker local para imagens ==="
docker run -d --restart=always -p 5000:5000 --name "${REGISTRY_NAME}" registry:2 || echo "Registro já existe"

echo "=== Conectando registry à rede do Kind ==="
docker network connect kind "${REGISTRY_NAME}" || true

echo "=== Criando cluster Kind '${CLUSTER_NAME}' ==="
kind create cluster --name "${CLUSTER_NAME}" --config ../kind-cluster.yaml || echo "Cluster já existe"

echo "=== Aguardando nodes ficarem Ready ==="
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo "=== Instalando Metrics Server ==="
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Remover quando migrar para cloud provider
echo "=== Aplicando Patch para usar insecure-tls no KIND ==="
kubectl patch deployment metrics-server -n kube-system \
  --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'


echo "=== Build das imagens ==="
docker build -t toggle-master-microservices-analytics-service ../../analytics-service/
docker build -t toggle-master-microservices-auth-service ../../auth-service/
docker build -t toggle-master-microservices-evaluation-service ../../evaluation-service/
docker build -t toggle-master-microservices-flag-service ../../flag-service/
docker build -t toggle-master-microservices-targeting-service ../../targeting-service/

echo "=== Gerando tags das imagens para o Docker ==="
docker tag toggle-master-microservices-analytics-service localhost:5000/toggle-master-microservices-analytics-service
docker tag toggle-master-microservices-auth-service localhost:5000/toggle-master-microservices-auth-service
docker tag toggle-master-microservices-evaluation-service localhost:5000/toggle-master-microservices-evaluation-service
docker tag toggle-master-microservices-flag-service localhost:5000/toggle-master-microservices-flag-service
docker tag toggle-master-microservices-targeting-service localhost:5000/toggle-master-microservices-targeting-service

echo "=== Enviando as imagens ao registry local (Docker) ==="
docker push localhost:5000/toggle-master-microservices-analytics-service
docker push localhost:5000/toggle-master-microservices-auth-service
docker push localhost:5000/toggle-master-microservices-evaluation-service
docker push localhost:5000/toggle-master-microservices-flag-service
docker push localhost:5000/toggle-master-microservices-targeting-service    

echo "=== Criando namespace toggle-master ==="
kubectl apply -f ../namespace.yaml

echo "=== Instalando MetalLB ==="
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

echo "=== Aguardando controller do MetalLB ==="
kubectl wait -n metallb-system --for=condition=available deployment/controller --timeout=180s

echo "=== Aplicando configuração do MetalLB ==="
kubectl apply -f ../metallb-config.yaml

echo "=== Aguardando pods Speaker do MetalLB ==="
kubectl wait -n metallb-system --for=condition=Ready pod -l component=speaker --timeout=180s

echo "=== Instalando ingress-nginx bare-metal (v1.9.5) ==="
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/baremetal/deploy.yaml

echo "=== Aguardando Ingress Controller ficar pronto ==="
kubectl wait --namespace ingress-nginx --for=condition=available deployment/ingress-nginx-controller --timeout=180s

echo "=== Aguardando webhook de admission subir ==="
for i in {1..50}; do
  if kubectl get validatingwebhookconfigurations | grep -q ingress-nginx-admission; then
    echo "Webhook encontrado, testando conexão..."
    if kubectl run tmp --rm -i --restart=Never --image=busybox -- \
      sh -c "nc -zv ingress-nginx-controller-admission.ingress-nginx.svc 443" >/dev/null 2>&1; then
      echo "Webhook pronto!"
      break
    fi
  fi

  echo "Aguardando webhook (tentativa $i)..."
  sleep 4
done

echo "=== Aplicando ConfigMaps ==="
kubectl apply -f ../configmaps -n toggle-master

echo "=== Aplicando Secrets ==="
kubectl apply -f ../secrets -n toggle-master

echo "=== Aplicando Deployments ==="
kubectl apply -f ../deployments -n toggle-master

echo "=== Aplicando Services ClusterIP ==="
kubectl apply -f ../services -n toggle-master

echo "=== Aplicando Ingress ==="
kubectl apply -f ../ingress.yaml -n toggle-master

echo "=== Alterando Service do Ingress para LoadBalancer ==="
kubectl patch svc ingress-nginx-controller \
  -n ingress-nginx \
  -p '{"spec": {"type": "LoadBalancer"}}'

echo "=== Recursos Criados ==="
kubectl get pods -n toggle-master
kubectl get svc -n toggle-master
kubectl get ingress -n toggle-master
kubectl get svc -n ingress-nginx
kubectl get pods -n ingress-nginx
