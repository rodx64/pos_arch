# 🛠️ Hands-On 04 — Parte 2: Roteamento Avançado e Deploy Gradual no Istio

## 🎯 Objetivos

- Subir **duas versões** de um serviço (v1 e v2) e expor via **Gateway** do Istio.
- Definir **subsets** com `DestinationRule`.
- Implementar **Canary** (90% v1 / 10% v2).
- Implementar **A/B Testing** roteando para v2 quando o header `x-test-user=beta-tester` estiver presente.

---

## 📂 Estrutura de Arquivos

```
hands-on-04-parte2-istio-routing/
├── helloworld-v1-deployment.yaml
├── helloworld-v1-service.yaml
├── helloworld-v2-deployment.yaml
├── helloworld-v2-service.yaml
├── helloworld-destinationrule.yaml
├── helloworld-virtualservice-100-v1.yaml
├── helloworld-virtualservice-canary.yaml
├── helloworld-virtualservice-abtest.yaml
└── README.md
```

---

## 🔧 Pré-requisitos

- **Minikube ou Kind** rodando e `kubectl` configurado.
- **Istio instalado e validado** (ver Aula 4 — Parte 1).
- Namespace com injeção automática habilitada:
  ```bash
  kubectl label ns default istio-injection=enabled --overwrite
  ```

### Windows — `minikube tunnel`

Abra um PowerShell **como Administrador** e deixe o túnel ativo:
```powershell
minikube tunnel
```

---

## 🚀 Passo a passo

### 1) Obter endpoint do Istio IngressGateway
```bash
kubectl get svc -n istio-system
```

Se usar `minikube tunnel`, normalmente:
```powershell
curl.exe http://127.0.0.1
```
```bash
curl http://127.0.0.1
```

Se não usar tunnel (NodePort ex.: 31729):
```powershell
curl.exe http://127.0.0.1:31729
```
```bash
curl http://127.0.0.1:31729
```

---

### 2) Implantar as duas versões e o Service
```bash
kubectl apply -f helloworld-v1-deployment.yaml
kubectl apply -f helloworld-v1-service.yaml
kubectl apply -f helloworld-v2-deployment.yaml
kubectl get pods -l app=helloworld
kubectl get svc helloworld
```

---

### 3) Criar Gateway e DestinationRule
```bash
kubectl apply -f helloworld-gateway.yaml
kubectl get gateway

kubectl apply -f helloworld-destinationrule.yaml
kubectl get destinationrule helloworld-destinationrule
```

---

### 4) VirtualService inicial — 100% v1
```bash
kubectl apply -f helloworld-virtualservice-100-v1.yaml
kubectl get virtualservice helloworld-virtualservice
```

**Testar:**
Windows PowerShell
```powershell
$N=200; $hits = 1..$N | % {
  $body = (Invoke-WebRequest -UseBasicParsing "http://127.0.0.1").Content
  if ($body -match "helloworld-v1") {"v1"}
  elseif ($body -match "helloworld-v2") {"v2"}
}
$hits | Group-Object | Sort-Object Count -desc | Format-Table
```
Linux/macOS
```bash
N=200; for i in $(seq 1 $N); do curl -s http://127.0.0.1; done | sort | uniq -c
```

> Resultado esperado: apenas v1

---

### 5) Canary — 90% v1 / 10% v2
```bash
kubectl apply -f helloworld-virtualservice-canary.yaml
```

**Testar:**
Windows PowerShell
```powershell
$N=200; $hits = 1..$N | % {
  $body = (Invoke-WebRequest -UseBasicParsing "http://127.0.0.1").Content
  if ($body -match "helloworld-v1") {"v1"}
  elseif ($body -match "helloworld-v2") {"v2"}
}
$hits | Group-Object | Sort-Object Count -desc | Format-Table
```
Linux/macOS
```bash
N=200; for i in $(seq 1 $N); do curl -s http://127.0.0.1; done | sort | uniq -c
```

> Esperado: maioria v1, cerca de 10% v2

---

### 6) A/B Testing — header `x-test-user=beta-tester`
```bash
kubectl apply -f helloworld-virtualservice-abtest.yaml
```

**Sem header → v1**  
Windows PowerShell
```powershell
$N=200; $hits = 1..$N | % {
  $body = (Invoke-WebRequest -UseBasicParsing "http://127.0.0.1").Content
  if ($body -match "helloworld-v1") {"v1"}
  elseif ($body -match "helloworld-v2") {"v2"}
}
$hits | Group-Object | Sort-Object Count -desc | Format-Table
```
Linux/macOS
```bash
N=200; for i in $(seq 1 $N); do curl -s http://127.0.0.1; done | sort | uniq -c
```

> Resultado esperado: 100% v1

**Com header → v2**  
Windows PowerShell
```powershell
$N=200; $hits = 1..$N | % {
  $headers = @{"x-test-user"="beta-tester"}
  $body = (Invoke-WebRequest -UseBasicParsing -Headers $headers "http://127.0.0.1").Content
  if ($body -match "helloworld-v1") {"v1"}
  elseif ($body -match "helloworld-v2") {"v2"}
}
$hits | Group-Object | Sort-Object Count -desc | Format-Table
```
Linux/macOS
```bash
N=200; for i in $(seq 1 $N); do curl -s -H "x-test-user: beta-tester" http://127.0.0.1; done | sort | uniq -c
```

> Resultado esperado: 100% v2

---

## 🧹 Limpeza
```bash
kubectl delete -f helloworld-virtualservice-abtest.yaml --ignore-not-found
kubectl delete -f helloworld-virtualservice-canary.yaml --ignore-not-found
kubectl delete -f helloworld-virtualservice-100-v1.yaml --ignore-not-found
kubectl delete -f helloworld-destinationrule.yaml
kubectl delete -f helloworld-v2-deployment.yaml
kubectl delete -f helloworld-v1-service.yaml
kubectl delete -f helloworld-v1-deployment.yaml
minikube delete
```

---

## ✅ Conceitos demonstrados

- Gateway, VirtualService e DestinationRule no Istio
- Subsets e roteamento L7
- Canary (weights) e A/B (headers)

---

## ▶️ Próxima Aula — Parte 3: Segurança e Observabilidade no Istio

5. Segurança com mTLS no Istio  
6. Observabilidade com Istio (métricas, tracing e logging)  
