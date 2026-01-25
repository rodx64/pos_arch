# 🛠️ Hands-On 04 --- Parte 3: Segurança (mTLS) e Observabilidade no Istio

## 🎯 Objetivos

- Ativar **mTLS** no Istio em modo **PERMISSIVE** e depois **STRICT**.  
- Validar tráfego criptografado dentro do Service Mesh.  
- Instalar e explorar as ferramentas de **observabilidade**: Grafana (métricas), Jaeger (tracing) e Kiali (topologia e status mTLS).  

------------------------------------------------------------------------

## 📂 Estrutura de Arquivos

```
hands-on-04-parte3-istio-security-obs/
├── mesh-peerauthentication-permissive.yaml
├── mesh-peerauthentication-strict.yaml
└── README.md
```

------------------------------------------------------------------------

## 🔧 Pré-requisitos

- Cluster Kubernetes (Minikube ou Kind).  
- `kubectl` configurado.  
- Istio instalado com perfil **default** (se usou `demo`, pode pular o passo de instalar os add-ons).  
- Namespace com injeção automática:  
  ```bash
  kubectl label ns default istio-injection=enabled --overwrite
  ```
- A aplicação `helloworld` (v1/v2) já deve estar implantada (reuso da **Parte 2**).  

------------------------------------------------------------------------

## 🚀 Passo a passo

### 1) Instalar ferramentas de observabilidade

O perfil `default` do Istio **não instala Grafana, Jaeger e Kiali**.  
Instale os add-ons com recursos mínimos (ideal para Minikube):  

```bash
# Clonar repositório oficial de samples
git clone https://github.com/istio/istio.git
cd istio/samples/addons

# Instalar cada componente (com configs reduzidas)
kubectl apply -f prometheus.yaml
kubectl apply -f grafana.yaml
kubectl apply -f jaeger.yaml
kubectl apply -f kiali.yaml
```

> ⚠️ Isso cria serviços `grafana`, `jaeger-query` e `kiali` no namespace `istio-system`.

------------------------------------------------------------------------

### 2) Validar cluster, Istio e aplicação

```bash
minikube status
kubectl get pods -n istio-system
kubectl get pods -l app=helloworld
```

Testar endpoint do **Ingress Gateway** (ajuste porta/IP conforme seu ambiente):

```powershell
curl.exe http://127.0.0.1
```

```bash
curl http://127.0.0.1
```

------------------------------------------------------------------------

### 3) Ativar mTLS em modo PERMISSIVE

Aplicar configuração:

```bash
kubectl apply -f mesh-peerauthentication-permissive.yaml
```

Verificar status:

```bash
kubectl get peerauthentication -A
```

**Explicação**:  
- 🔓 **PERMISSIVE** = o Istio aceita tráfego **mTLS** e também tráfego **sem criptografia**.  
- Útil para migração gradual, pois não quebra quem ainda não tem sidecar injetado.  
- No Kiali, conexões podem aparecer **sem cadeado** (tráfego plain text) e **com cadeado** (mTLS).  

------------------------------------------------------------------------

### 4) Ativar mTLS em modo STRICT

Aplicar configuração:

```bash
kubectl apply -f mesh-peerauthentication-strict.yaml
```

Verificar status:

```bash
kubectl get peerauthentication -A   
```

**Explicação**:  
- 🔐 **STRICT** = todo tráfego **dentro do mesh** deve ser criptografado via mTLS.  
- Se um pod não tiver o sidecar do Istio injetado, sua comunicação será **bloqueada**.  
- No Kiali, todas as conexões devem mostrar cadeado verde (mTLS ativo).  

------------------------------------------------------------------------

### 5) Gerar tráfego para observabilidade

Windows PowerShell
```powershell
1..100 | % { curl.exe -s http://127.0.0.1 > $null }
```

Linux/macOS
```bash
for i in {1..100}; do curl -s http://127.0.0.1 > /dev/null; done
```

------------------------------------------------------------------------

### 6) Abrir ferramentas de Observabilidade (3 consoles separados)

---

### ⚙️ (Ajuste Necessário) Habilitar Tracing no Istio

> Por padrão, o Istio **não envia traces** para o Jaeger até que a configuração de tracing seja ativada.

```bash
kubectl -n istio-system edit configmap istio
```

Adicione (ou verifique) o seguinte bloco:

```yaml
data:
  mesh: |-
    defaultConfig:
      tracing:
        sampling: 100
        zipkin:
          address: jaeger-collector.istio-system.svc.cluster.local:9411
```

```bash
kubectl rollout restart deployment istiod -n istio-system
kubectl rollout restart deployment -n default
```

Gere tráfego:

Windows PowerShell
```powershell
1..50 | ForEach-Object { Invoke-WebRequest -UseBasicParsing "http://127.0.0.1" | Out-Null }
```
Linux/macOS
```bash
for i in $(seq 1 50); do curl -s http://127.0.0.1; donc
```

---

Abra **3 terminais diferentes** e rode os port-forwards:

```bash
# Console 1 - Grafana
kubectl -n istio-system port-forward svc/grafana 3000:3000

# Console 2 - Jaeger
kubectl -n istio-system port-forward svc/tracing 16686:80

# Console 3 - Kiali
kubectl -n istio-system port-forward svc/kiali 20001:20001
```

Acesse no navegador:

- **Grafana**: <http://localhost:3000>  
  - Dashboards `Istio / Mesh` e `Istio / Workload`.  
  - Observe volume de requisições, taxa de sucesso, latência.  

- **Jaeger**: <http://localhost:16686>  
  - Selecione `helloworld`.  
  - Explore os traces → veja o caminho da requisição do ingress até o serviço.  

- **Kiali**: <http://localhost:20001/kiali> (login padrão `admin/admin`)  
  - Vá em **Graph** e escolha o namespace `default`.  
  - **Cadeado verde = mTLS ativo**.  
  - Se estiver em **PERMISSIVE**, pode ver conexões sem cadeado (plain text).  
  - Em **STRICT**, todas as conexões devem mostrar cadeado verde.  
  - Clicar no serviço `helloworld` para detalhes: métricas, traces e logs.  

------------------------------------------------------------------------

## 🧹 Limpeza

```bash
kubectl delete -f mesh-peerauthentication-strict.yaml --ignore-not-found
kubectl delete -f mesh-peerauthentication-permissive.yaml --ignore-not-found
# Opcional: remover app helloworld e parar o minikube
minikube delete
```

------------------------------------------------------------------------

## ✅ Conceitos demonstrados

- Diferença entre **PERMISSIVE** (migração suave) e **STRICT** (segurança total).  
- Como ativar **mTLS** em todo o mesh com `PeerAuthentication`.  
- Uso de **Grafana, Jaeger e Kiali** para visualizar segurança, métricas e topologia.  
