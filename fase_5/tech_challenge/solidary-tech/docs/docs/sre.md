# SRE e Confiabilidade

> Relatório completo do projeto para [SRE][1]

## SLIs e SLOs do `donation-service`

O `donation-service` é o serviço crítico de negócio (jornada de doação) e por isso concentra os SLOs formais do projeto, baseados nos [Quatro Sinais de Ouro](https://sre.google/sre-book/monitoring-distributed-systems/#xref_monitoring_golden-signals) (Google SRE Book):

| SLI | Definição | SLO |
|---|---|---|
| **Taxa de sucesso** | % de requisições sem erro `5xx` | **99.9%** (janela móvel de 30 dias) |
| **Latência** | % de requisições respondidas em ≤ 250ms | **95.0%** |
| **Jornada de doação (composto)** | % de traces raiz `POST /donations` concluídos com sucesso, considerando toda a árvore de chamadas distribuída | **99.0%** |

O SLI de jornada é o mais importante dos três: ele só fica saudável se **todas** as dependências (banco, SQS, downstream) estiverem saudáveis — é o indicador mais próximo da experiência real do doador.

## Dashboard de SRE e Error Budget

O painel de SRE é provisionado via **Terraform** (provider Datadog), não criado manualmente — módulo `terraform/modules/observability`. Ele acompanha o **consumo do Error Budget**: em vez de alertar em limites de infraestrutura (ex: "CPU > 80%"), o alerta principal é a **taxa de queima do orçamento de erro** (*burn rate*), seguindo a recomendação do [Site Reliability Workbook](https://www.oreilly.com/library/view/the-site-reliability/9781492029496/) — um burn rate acima de `14.4x` significa que, se mantido, o SLO mensal será violado, e isso é o que dispara o alerta de SEV1 (ver [AIOps e Gestão de Incidentes](./itsm-aiops.md)).

## Redução de MTTR

Três mecanismos reduzem ativamente o tempo de recuperação:

1. **MTTI menor** via alertas de burn rate (detecção em segundos, não em "alguém notar").
2. **Triagem mais rápida** via tracing distribuído (OpenTelemetry) cruzando Go e Python — a árvore de execução de uma falha é determinística, não exige inspeção manual de cada componente.
3. **Ponte de contexto** entre métricas e logs no Datadog APM — de um pico anômalo direto para a linha de log/trace correspondente.

[1]: https://github.com/rodx64/pos_arch/blob/develop/fase_5/tech_challenge/doc/2_SRE.md
