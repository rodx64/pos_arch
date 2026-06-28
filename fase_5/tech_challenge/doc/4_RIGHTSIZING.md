# Rightsizing e Estratégia de Scaling — Solidary Tech
## Decisão implementada: KEDA (Prometheus + CPU) para `donation-service`, HPA nativo para `ngo`/`volunteer`, rightsizing diferenciado por serviço

Este documento registra a decisão de FinOps **"Rightsizing"** efetivamente implementada: os valores de `requests`/`limits` adotados por serviço, e a estratégia de scaling escolhida — KEDA apenas onde já há sinal e ferramenta disponíveis (`donation-service`), mantendo HPA nativo nos demais. As alternativas avaliadas e descartadas foram removidas; o que segue é o caminho adotado.

---

## 1. Scaling: o que foi implementado

**Decisão:** scaling baseado em fila **não foi adotado**. A `donation-queue` hoje só tem produtor (`donation-service` publica após cada doação) — não existe consumidor no código atual, então não há [profundidade de fila](https://www.ibm.com/docs/pt-br/ibm-mq/9.4.x?topic=events-queue-depth) com relação causal a escalar contra. Fica registrado como escopo futuro, sem implementação: se um *worker* vier a consumir `donation-queue`, o padrão a seguir é KEDA com o *scaler* `aws-sqs-queue` e `identityOwner: operator` (credencial do nó), permitindo `minReplicaCount: 0`.

**O que foi implementado:** KEDA, escalando o `donation-service` por **tráfego HTTP** (sinal correto para uma API I/O, já coletado pelo Prometheus em `http_requests_total`), com CPU como rede de segurança.

### 1.1. Instalação do KEDA (pipeline)

KEDA é tratado como add-on de cluster — mesmo padrão usado para ArgoCD/Metrics Server/ingress-nginx — instalado no job **`cluster-addons`** (`Install — Cluster Add-ons`) da workflow [`CI/CD — Terraform Infrastructure`](../../../.github/workflows/ci-infra.yml):

```yaml
      - name: Install KEDA
        run: |
          if kubectl get deployment keda-operator -n keda &>/dev/null; then
            echo "KEDA já instalado — pulando instalação."
          else
            echo "Instalando KEDA ${{ env.KEDA_VERSION }}..."
            kubectl apply --server-side -f https://github.com/kedacore/keda/releases/download/v${{ env.KEDA_VERSION }}/keda-${{ env.KEDA_VERSION }}.yaml
            kubectl wait --namespace keda --for=condition=Ready pod -l app=keda-operator --timeout=180s
          fi
```

### 1.2. `ScaledObject` do `donation-service` (GitOps)

Arquivo novo, sincronizado pelo ArgoCD (já cai no `recurse: true` da `Application`, sem job de pipeline dedicado):

[`eks/deployments/keda/donation-scaling.yaml`](../solidary-tech/eks/deployments/keda/donation-scaling.yaml)
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: donation-scaledobject
  namespace: solidary-tech
spec:
  scaleTargetRef:
    name: donation-deployment
  minReplicaCount: 1
  maxReplicaCount: 4   # serviço crítico de SLO (99.9% / P99 250ms)
  cooldownPeriod: 120
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://prometheus.monitoring.svc.cluster.local:9090
        metricName: donation_http_request_rate
        query: sum(rate(http_requests_total{service="donation"}[2m]))
        threshold: "50"
    - type: cpu
      metricType: Utilization
      metadata:
        value: "70"
```

KEDA cria o `HorizontalPodAutoscaler` correspondente por baixo dos panos; por isso o `donation-hpa.yaml` antigo foi **removido**.

### 1.3. `ngo-service` e `volunteer-service`: continuam no HPA nativo

Sem baseline de tráfego (req/s) calibrada para esses dois serviços ainda, eles **não migram para KEDA agora** — permanecem no `HorizontalPodAutoscaler` padrão do Kubernetes, apenas com o threshold ajustado (Seção 2.4). Migrar para KEDA com trigger de Prometheus é o próximo passo natural, uma vez que o `/cpu` (Seção 1.4) gerar uma baseline real de uso.

### 1.4. Endpoint `/cpu`: implementado

A rota `/cpu` foi implementada nos 3 serviços (`donation-service` em Go, `ngo-service` e `volunteer-service` em Python) como endpoint sintético de estresse de CPU, sem efeito sobre banco de dados ou fila. O teste de carga já tem rota real para gerar o sinal usado nos thresholds acima.

---

## 2. Rightsizing dos 3 serviços

### 2.1. Diagnóstico do estado anterior

Os 3 deployments usavam **valores genéricos idênticos**, independente da stack:

```yaml
resources:
  limits:
    memory: "256Mi"
    cpu: "500m"
  requests:
    memory: "128Mi"
    cpu: "250m"
```

| Serviço | Runtime | Modelo de processo | Observação |
|---|---|---|---|
| `donation-service` | Go (binário compilado) | 1 processo, goroutines | Baixo overhead de memória; CPU sobe só sob carga real (JSON, OTel, pgx) |
| `ngo-service` | Python/Flask + Gunicorn `-w 4` | 4 processos Python completos | Overhead de memória multiplicado por 4 (Flask + OTel + psycopg2 por worker) |
| `volunteer-service` | Python/Flask + Gunicorn `-w 4` | 4 processos Python completos | Igual ao `ngo`, sem pool de conexão Postgres (usa boto3/DynamoDB) |

4 workers Gunicorn dentro de um container limitado a `256Mi`/`500m` arrisca OOMKill sob carga real e *throttling* de CPU silencioso (4 processos competindo por menos de 1 vCPU). O serviço Go estava sobre-provisionado; os serviços Python, sub-provisionados para o modelo de 4 workers.

### 2.2. Metodologia de validação adotada

Validação via carga real gerada pelo [`k6-load-test.yaml`](../solidary-tech/eks/k6-load-test.yaml) contra o endpoint `/cpu` (Seção 2.4), observada por estas duas queries PromQL:

```promql
quantile_over_time(0.95, container_memory_working_set_bytes{namespace="solidary-tech"}[30m])
quantile_over_time(0.95, rate(container_cpu_usage_seconds_total{namespace="solidary-tech"}[2m])[30m:])
```

Os valores da Seção 2.3 são o ponto de partida aplicado nos manifestos; o P95 observado nessas queries, após uma execução do `k6-load-test.yaml`, foi o critério para calibração.

### 2.3 Valores aplicados

| Serviço | requests.cpu | requests.memory | limits.cpu | limits.memory | Ajuste de código |
|---|---|---|---|---|---|
| `donation-service` | **100m** | **80Mi** | **300m** | **150Mi** | Nenhum (Go já é leve) |
| `ngo-service` | **150m** | **200Mi** | **400m** | **350Mi** | Gunicorn `-w 4` → `-w 2` |
| `volunteer-service` | **120m** | **180Mi** | **350m** | **300Mi** | Gunicorn `-w 4` → `-w 2` |

**Por que reduzir os workers do Gunicorn:** o padrão em Kubernetes é escalar **horizontalmente** (mais réplicas via HPA/KEDA), não **verticalmente** (mais workers por pod). Com 4 workers competindo por `500m` (meio vCPU), o ganho de paralelismo é anulado por [*context switching*](https://medium.com/devops-dudes/what-is-context-switching-and-how-to-minimize-it-1eb6ac099333); com 2 workers e CPU/memória dimensionados corretamente, cada processo tem mais "ar" e o autoscaler absorve os picos.

**Impacto agregado (3 réplicas cada, pior caso = todos no limite simultaneamente):**

| | CPU total (limits) | Memória total (limits) |
|---|---|---|
| **Antes** (uniforme) | 3 × 3 × 500m = 4.500m | 3 × 3 × 256Mi = 2.304Mi |
| **Depois** (diferenciado) | (300+400+350) × 3 = 3.150m | (150+350+300) × 3 = 2.400Mi |

CPU reservável no pior caso cai **~30%**; a memória sobe ligeiramente (~4%), deliberadamente, para eliminar o risco de [OOMKill](https://dev.to/cod3mason/oomkill-in-kubernetes-and-linux-exit-code-137-20ba) nos serviços Python.

### 2.4. HPA — `ngo-service` e `volunteer-service`

(`donation-service` não usa mais HPA nativo — o threshold de CPU e o `maxReplicaCount` equivalentes já estão no `ScaledObject` da Seção 2.2.)

[`ngo-hpa.yaml`](../solidary-tech/eks/deployments/hpa/ngo-hpa.yaml) / [`volunteer-hpa.yaml`](../solidary-tech/eks/deployments/hpa/volunteer-hpa.yaml)
```yaml
spec:
  minReplicas: 1
  maxReplicas: 3
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70   # antes: 80
```

---

## 4. Resumo executivo

| Item | Decisão implementada |
|---|---|
| Scaling baseado em fila | Não implementado — sem consumidor da `donation-queue` hoje. Padrão definido para quando existir (`aws-sqs-queue` scaler, `identityOwner: operator`). |
| `donation-service` | KEDA `ScaledObject` (Prometheus + CPU), `minReplicaCount: 1`, `maxReplicaCount: 4`. HPA nativo removido. |
| `ngo-service` / `volunteer-service` | HPA nativo mantido, CPU `averageUtilization: 70%`, `maxReplicas: 3`. |
| Instalação do KEDA | Job `cluster-addons` (workflow `CI/CD — Terraform Infrastructure`), `kubectl apply --server-side`, idempotente. |
| Endpoint `/cpu` | Implementado nos 3 serviços — gap do `k6-load-test.yaml` resolvido. |
| Rightsizing | Valores diferenciados por serviço (Seção 3.3) aplicados nos manifestos; CPU reservável no pior caso reduzido em ~30%. |
