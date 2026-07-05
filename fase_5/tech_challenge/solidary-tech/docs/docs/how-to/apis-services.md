# Guia de APIs e Serviços

O ecossistema é composto por três microsserviços especializados, cada um com domínio, persistência e linguagem próprios:

## `donation-service` (Go)

**Repositório:** [`services/donation-service`][donation-repo]

O serviço crítico de negócio — toda doação passa por aqui. É o único serviço com SLO formal e monitoramento de error budget.

| Endpoint | Método | Descrição |
|---|---|---|
| `/donations` | POST | Cria uma doação; publica evento na `donation-queue` (SQS) |
| `/donations` | GET | Lista todas as doações |
| `/donations/health` | GET | Health check |
| `/metrics` | GET | Métricas Prometheus |
| `/cpu` | GET | Endpoint de carga sintética (usado pelo `k6-load-test.yaml` para calibração de rightsizing) |

**Persistência:** PostgreSQL (RDS `donation_db`) + SQS (`donation-queue` para eventos de notificação).

## `ngo-service` (Python/Flask)

**Repositório:** [`services/ngo-service`][ngo-repo]

Cadastro e gestão das ONGs parceiras da plataforma.

| Endpoint | Método | Descrição |
|---|---|---|
| `/ngos` | POST | Cadastra uma ONG |
| `/ngos` | GET | Lista todas as ONGs |
| `/ngos/health` | GET | Health check |
| `/metrics` | GET | Métricas Prometheus |

**Persistência:** PostgreSQL (RDS `ngo_db`).

## `volunteer-service` (Python/Flask)

**Repositório:** [`services/volunteer-service`][volunteer-repo]

Gestão de voluntários por ONG.

| Endpoint | Método | Descrição |
|---|---|---|
| `/volunteers` | POST | Cadastra um voluntário |
| `/volunteers/<ngo_id>` | GET | Lista voluntários de uma ONG específica (filtra por `ngo_id`) |
| `/volunteers/health` | GET | Health check |
| `/metrics` | GET | Métricas Prometheus |

**Persistência:** DynamoDB (`volunteer-table`, hash key: `volunteer_id`).

## Comunicação entre serviços

```
Doador → donation-service → PostgreSQL (donation_db)
                          → SQS (donation-queue)  ← sem consumidor hoje
```

Os serviços não se comunicam diretamente entre si — o acoplamento é via persistência independente e mensageria assíncrona (SQS). A `donation-queue` atualmente só tem produtor; o padrão para um futuro consumidor está documentado em [FinOps](../finops.md#scaling) (KEDA com `aws-sqs-queue` scaler).

## Instrumentação

Todos os serviços são instrumentados via OpenTelemetry:
- **Go:** `otelhttp` (middleware automático) + OTLP gRPC para o `otel-collector`
- **Python:** `opentelemetry-instrumentation-flask` + OTLP gRPC para o `otel-collector`

Cada serviço expõe `/metrics` (formato Prometheus) com `http_requests_total`, `http_request_duration_seconds`, `db_up`. O `donation-service` expõe adicionalmente `donations_created_total` — a golden metric de negócio.

[donation-repo]: https://github.com/rodx64/pos_arch/tree/develop/fase_5/tech_challenge/solidary-tech/services/donation-service
[ngo-repo]: https://github.com/rodx64/pos_arch/tree/develop/fase_5/tech_challenge/solidary-tech/services/ngo-service
[volunteer-repo]: https://github.com/rodx64/pos_arch/tree/develop/fase_5/tech_challenge/solidary-tech/services/volunteer-service
