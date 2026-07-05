# SRE e Confiabilidade

## SLIs e SLOs do `donation-service`

O `donation-service` é o serviço crítico de negócio (jornada de doação) e por isso concentra os SLOs formais do projeto, baseados nos [Quatro Sinais de Ouro](https://sre.google/sre-book/monitoring-distributed-systems/#xref_monitoring_golden-signals) (Google SRE Book):

| SLI | Definição | SLO |
|---|---|---|
| **Taxa de sucesso** | % de requisições sem erro `5xx` | **99.9%** (janela de 7 dias) |
| **Latência** | % de requisições respondidas em ≤ 250ms | **95.0%** |
| **Jornada de doação (composto)** | % de traces raiz `POST /donations` concluídos com sucesso, considerando toda a árvore de chamadas distribuída | **99.0%** |

O SLI de jornada é o mais importante dos três: ele só fica saudável se **todas** as dependências (banco, SQS, downstream) estiverem saudáveis — é o indicador mais próximo da experiência real do doador.

> **Janelas de avaliação:** o `availability_slo` (taxa de sucesso e latência) usa janela de **7 dias** (`timeframe: "7d"`) no Terraform — adequada para o contexto de laboratório com histórico operacional curto. O `business_journey_donation_slo` (jornada end-to-end) usa **30 dias** (`timeframe: "30d"`), por ser o SLO de negócio mais crítico e exigir uma janela mais ampla para refletir o comportamento real do doador.

Os SLOs são formalizados via **Terraform** (provider Datadog), no módulo [`terraform/modules/observability`][tf-observability] — não criados manualmente no painel. Os limiares são injetados dinamicamente pelo Terragrunt (`observability/dev/terragrunt.hcl`) via `slo_services`, o que torna o módulo reutilizável por qualquer serviço sem modificar o código Terraform. Para o `donation-service` em DEV, os valores configurados são: percentil de latência **P99**, limiar **0.25s**, target de disponibilidade **99.9%** (warning em **99.95%**). A métrica base é `solidary_tech.http_request_duration_seconds.count` (métrica Datadog derivada do OTel Collector), filtrada por `env`, `service` e `status`.

## Dashboard de SRE e Error Budget

O painel de SRE é provisionado via Terraform e acompanha o **consumo do Error Budget**: em vez de alertar em limites de infraestrutura (ex: "CPU > 80%"), o alerta principal é a **taxa de queima do orçamento de erro** (*burn rate*), seguindo a recomendação do [Site Reliability Workbook](https://www.oreilly.com/library/view/the-site-reliability/9781492029496/).

Um burn rate acima de **14.4×** significa que, se mantido, o SLO mensal será violado em menos de 1 hora — isso dispara o alerta de SEV1 (ver [AIOps e Gestão de Incidentes](./itsm-aiops.md)).

### Queries PromQL de referência

```promql
# P95 de memória por pod (30 min de janela)
quantile_over_time(0.95, container_memory_working_set_bytes{namespace="solidary-tech"}[30m])

# P95 de CPU por pod
quantile_over_time(0.95, rate(container_cpu_usage_seconds_total{namespace="solidary-tech"}[2m])[30m:])

# Taxa de requisições ao donation-service (base do ScaledObject KEDA)
sum(rate(http_requests_total{service="donation"}[2m]))
```

## Redução de MTTR

Três mecanismos reduzem ativamente o tempo de recuperação:

1. **MTTI menor** via alertas de burn rate — detecção em segundos, não quando alguém nota.
2. **Triagem mais rápida** via tracing distribuído (OpenTelemetry) cruzando Go e Python — a árvore de execução de uma falha é determinística, sem inspeção manual de cada componente.
3. **Ponte de contexto** entre métricas e logs no Datadog APM — de um pico anômalo direto para a linha de log/trace correspondente.
4. **Rollback em 1 commit** — a entrega GitOps (ArgoCD `selfHeal: true`) significa que reverter um deploy defeituoso é reverter o commit; o ArgoCD reconcilia automaticamente em segundos.

## Scaling orientado a SLO

O `donation-service` escala por **tráfego HTTP** (sinal correto para uma API I/O), gerenciado pelo **KEDA** com gatilho Prometheus + CPU como rede de segurança:

```yaml
# eks/deployments/keda/donation-scaling.yaml
triggers:
  - type: prometheus
    metadata:
      query: sum(rate(http_requests_total{service="donation"}[2m]))
      threshold: "50"
  - type: cpu
    metricType: Utilization
    metadata:
      value: "70"
```

`minReplicaCount: 1` / `maxReplicaCount: 4` — o limite superior protege o SLO sem deixar o custo descontrolado.

[tf-observability]: https://github.com/rodx64/pos_arch/tree/develop/fase_5/tech_challenge/solidary-tech/terraform/modules/observability
