# 🛠️ Hands‑On Aula 04 – Parte 1: Instalação e Primeiros Passos com Istio no Kubernetes

## 🚀 Por que usar o `istioctl` CLI?

O `istioctl` é a **ferramenta oficial de linha de comando do Istio**, criada para facilitar a vida de quem administra clusters Kubernetes com Service Mesh.  
Com ela, conseguimos:

- Instalar e atualizar o Istio de forma simples.  
- Validar se a instalação e a configuração estão corretas.  
- Depurar problemas de tráfego, segurança ou injeção de sidecars.  
- Analisar regras como VirtualServices e DestinationRules de forma prática.  

👉 Em resumo: o `istioctl` é o “canivete suíço” do Istio. Ele dá mais visibilidade, praticidade e segurança, evitando que os alunos precisem lidar com dezenas de YAMLs complexos.

---

## 🎯 Objetivo
Configurar e validar o Istio em um cluster Kubernetes local (Minikube ou Kind).  
Os alunos instalarão o Istio, habilitarão a injeção automática de sidecars e validarão a comunicação entre aplicações dentro da Service Mesh.

---

## 📋 Pré‑requisitos
- Docker Desktop ou Docker Engine instalado  
- `kubectl` instalado e configurado  
- Minikube ou Kind configurado (recomendado Minikube)  
- Acesso à internet para baixar Istio e imagens de containers  
- Git instalado para clonar exemplos (opcional)

---

## 📁 Estrutura de Arquivos
```
hands-on-04-parte1-istio/
└── README.md  (este documento com todos os comandos e explicações)
```

---

## 🚀 Passos

### 1. Iniciar ou Verificar Cluster Kubernetes

**Windows e Linux/MacOS:**
```bash
minikube delete
minikube start --memory=4096mb --cpus=2 --driver=docker
minikube status
```

---

### 2. Baixar e Instalar `istioctl`

#### 💻 Usuários Windows – Usando Chocolatey (recomendado)

O **Chocolatey** é um gerenciador de pacotes para Windows (similar ao `apt` no Linux ou `brew` no macOS). Ele permite instalar ferramentas como o `istioctl` de forma rápida e automatizada.

**Instalar o Chocolatey (se ainda não tiver):**
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; `
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

Depois feche e reabra o PowerShell.

**Instalar o Istio com Chocolatey:**
```powershell
choco install istioctl -y
istioctl version
```

---

#### 🐧 Linux / 🍏 macOS – Usando Bash

```bash
export ISTIO_VERSION="1.20.0"
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -
cd istio-${ISTIO_VERSION}
export PATH=$PWD/bin:$PATH
istioctl version
```

---

### 3. Instalar o Istio no Cluster Kubernetes
```bash
istioctl install --set profile=default -y
kubectl get pods -n istio-system
kubectl get svc -n istio-system
```

---

### 4. Validar a Instalação do Istio
```bash
kubectl get crd 
```
---

### 5. **Demonstração prática**: Injeção de Sidecar (antes & depois)
Nesta etapa vamos **provar** a injeção automática do sidecar Envoy.

**5.1 – Crie um namespace *sem* habilitar a injeção e suba um app simples**
```bash
kubectl create namespace dev-app
kubectl -n dev-app create deployment demo --image=nginxdemos/hello
kubectl -n dev-app expose deployment demo --port=80 --type=ClusterIP
```

**Cheque os containers do Pod (deve ter só 1 – o app):**
```bash
kubectl -n dev-app get pods 
# Saída esperada: CONTAINERS = "1/1"
```

**5.2 – *Agora* habilite a injeção no namespace**
```bash
kubectl label namespace dev-app istio-injection=enabled --overwrite=true
```

**5.3 – Force um *rollout restart* para recriar os Pods já com o sidecar**
```bash
kubectl -n dev-app rollout restart deployment demo
kubectl -n dev-app rollout status  deployment demo
```

**Verifique novamente os containers do Pod (deve ter 2 – app + istio-proxy):**
```bash
kubectl -n dev-app get pods 
# Saída esperada: CONTAINERS = "2/2"
```

> **Dica**: se preferir, você pode apagar os Pods ao invés do `rollout restart`:
> ```bash
> kubectl -n dev-app delete pod -l app=demo
> ```
> O Deployment recria os Pods já com sidecar.

**(Opcional) Teste rápido de acesso**
```bash
kubectl -n dev-app port-forward deploy/demo 8080:80
# Acesse http://localhost:8080
```

---

## 🎯 Conclusão
Pronto! Agora o Istio está instalado e pronto para gerenciar o tráfego dos microserviços.

Na próxima aula (Parte 2), exploraremos:
- Roteamento avançado com `VirtualService` e `DestinationRule`  
- Estratégias de Canary Deployment e A/B Testing  

**Hands-on:** Configurar `VirtualService` para roteamento 10%/90% e A/B Testing baseado em headers HTTP.

---
