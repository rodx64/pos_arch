# Guia de APIs e Serviços

O ecossistema é composto por três microsserviços especializados, cada um com domínio, persistência e linguagem próprios. A documentação abaixo considera o uso local, assumindo que cada serviço esteja rodando nas portas padrão: `8081` para o `ngo-service`, `8082` para o `donation-service` e `8083` para o `volunteer-service`.

## `donation-service` (Go)

**Repositório:** [`services/donation-service`][donation-repo]

O serviço crítico de negócio — toda doação passa por aqui. Ele persiste registros no PostgreSQL e, quando configurado, publica eventos na fila SQS.

| Endpoint | Método | Descrição |
|---|---|---|
| `/donations/health` | GET | Health check |
| `/donations` | POST | Cria uma doação |
| `/donations` | GET | Lista todas as doações |
| `/cpu` | GET | Endpoint sintético de carga de CPU |
| `/metrics` | GET | Métricas Prometheus |

**Persistência:** PostgreSQL (RDS `donation_db`) + SQS (`donation-queue` para eventos de notificação).

### Exemplos locais com curl

```bash
curl http://localhost:8082/donations/health
```

```bash
curl http://localhost:8082/donations
```

```bash
curl -X POST http://localhost:8082/donations \
  -H "Content-Type: application/json" \
  -d '{"ngo_id": 1, "amount": 25.5, "donor_name": "Maria"}'
```

```bash
curl "http://localhost:8082/cpu?duration_ms=100"
```

```bash
curl http://localhost:8082/metrics
```

## `ngo-service` (Python/Flask)

**Repositório:** [`services/ngo-service`][ngo-repo]

Cadastro e gestão das ONGs parceiras da plataforma.

| Endpoint | Método | Descrição |
|---|---|---|
| `/ngos/health` | GET | Health check |
| `/ngos` | POST | Cadastra uma ONG |
| `/ngos` | GET | Lista todas as ONGs |
| `/cpu` | GET | Endpoint sintético de carga de CPU |
| `/metrics` | GET | Métricas Prometheus |

**Persistência:** PostgreSQL (RDS `ngo_db`).

### Exemplos locais com curl

```bash
curl http://localhost:8081/ngos/health
```

```bash
curl http://localhost:8081/ngos
```

```bash
curl -X POST http://localhost:8081/ngos \
  -H "Content-Type: application/json" \
  -d '{"name": "ONG Exemplo", "email": "contato@ong.org", "cause": "Educação", "city": "São Paulo"}'
```

```bash
curl "http://localhost:8081/cpu?duration_ms=100"
```

```bash
curl http://localhost:8081/metrics
```

## `volunteer-service` (Python/Flask)

**Repositório:** [`services/volunteer-service`][volunteer-repo]

Gestão de voluntários por ONG.

| Endpoint | Método | Descrição |
|---|---|---|
| `/volunteers/health` | GET | Health check |
| `/volunteers` | POST | Cadastra um voluntário |
| `/volunteers/<ngo_id>` | GET | Lista voluntários de uma ONG específica |
| `/cpu` | GET | Endpoint sintético de carga de CPU |
| `/metrics` | GET | Métricas Prometheus |

**Persistência:** DynamoDB (`volunteer-table`, hash key: `volunteer_id`).

### Exemplos locais com curl

```bash
curl http://localhost:8083/volunteers/health
```

```bash
curl -X POST http://localhost:8083/volunteers \
  -H "Content-Type: application/json" \
  -d '{"name": "Ana", "email": "ana@email.com", "ngo_id": 1}'
```

```bash
curl http://localhost:8083/volunteers/1
```

```bash
curl "http://localhost:8083/cpu?duration_ms=100"
```

```bash
curl http://localhost:8083/metrics
```

## Comunicação entre serviços

```text
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
